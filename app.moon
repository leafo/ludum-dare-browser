lapis = require "lapis"
db = require "lapis.db"

import to_json, from_json from require "lapis.util"
json = require "cjson"

config = require("lapis.config").get!
import Games, Events, Collections from require "models"

import respond_to from require "lapis.application"
import image_signature from require "helpers.image_signature"

CONTENT_TYPES = {
  jpg: "image/jpeg"
  png: "image/png"
  gif: "image/gif"
}

COLLECTIONS = {
  love: { "Love", {"love", "love2d"} }
  python: { "Python", {"python", "pygame"} }
  unity: { "Unity", {"unity"} }
  xna: { "XNA", {"xna"} }
  flash: { "Flash", {"flash", "swf"} }
  html5: { "HTML5", {"html5"} }
  java: { "Java", {"java", "jar"} }

  linux: { "Linux", {"linux"} }
  windows: { "Windows", {"windows", "win32"} }
  osx: { "OSX", {"os/x", "osx", "os x"} }
  android: { "Android", {"android"} }
}

-- eg. search for love games:
-- love_games = search_downloads("\\blove\\b", "i")
search_downloads = (games=Games\select!, ...) ->
  match = ngx.re.match

  found = {}
  for game in *games
    for d in *game.downloads
      if match(d.href, ...) or match(d.label, ...)
        table.insert found, game
        break

  found


class LudumDare extends lapis.Application
  "/game/:event_slug/:uid": =>
    event = Events\find slug: @params.event_slug
    return "invalid event", status: 404 unless event

    game = Games\find event_id: event.id, uid: @params.uid
    return "invalid game", status: 404 unless game

    game\fetch_details!
    json: game

  [screenshot_sized: "/game/:game_id/image/:image_id/:size"]: =>
    image_id = tonumber(@params.image_id) or 1

    signature = image_signature @req.parsed_url.path
    if @params.sig != signature
      return status: 403, "invalid signature"

    game = Games\find @params.game_id
    return status: 404, "missing game" unless game

    cache_name = "resized_" .. ngx.md5(@req.parsed_url.path) .. ".png"

    blob, err_or_ext = game\load_screenshot image_id
    return status: 404, err_or_ext unless blob

    -- bail on gif, we don't know how to resize
    if err_or_ext\lower! == "gif"
      ngx.header["x-image-gif"] = "1"
      return content_type: CONTENT_TYPES.gif, layout: false, blob

    magick = require "magick"
    img = magick.load_image_from_blob blob
    img\set_format "png"
    size = @params.size
    -- handle tall images differently
    ar = img\get_width! / img\get_height!
    if ar > 2 or 1/ar > 2
      size = size .. "#"

    resized_blob = magick.thumb img, size

    with io.open "cache/#{cache_name}", "w"
      \write resized_blob
      \close!

    ngx.header["x-image-cache"] = "miss"
    content_type: CONTENT_TYPES.png, layout: false, resized_blob

  -- get the raw image cached on our side
  [screnshot_raw: "/game/:game_id/image/:image_id"]: =>
    image_id = tonumber(@params.image_id) or 1
    game = Games\find @params.game_id
    return status: 404, "missing game" unless game

    image_blob, ext_or_err, cache_hit = game\load_screenshot image_id
    return status: 404, ext_or_err unless image_blob

    ngx.header["x-image-cache"] = cache_hit and "hit" or "miss"
    content_type: CONTENT_TYPES[ext_or_err], layout: false, image_blob

  "/games/:event_slug": =>
    event = Events\find slug: @params.event_slug

    unless event
      return { status: 404, "invalid event" }

    page = tonumber(@params.page) or 0
    limit = 40
    offset = page * limit

    sorts = {
      votes: "order by votes_received desc, votes_given desc, title asc"
      votes_reverse: "order by votes_received asc, votes_given desc, title desc"

      coolness: "order by votes_given desc, votes_received asc, title asc"
      coolness_reverse: "order by votes_given asc, votes_received desc, title desc"
      random: "random" -- done below
    }

    sort = sorts[@params.sort] or sorts.votes

    collection = @params.collection
    inner_join = if collection and COLLECTIONS[collection]
      "inner join collections on
        collections.name = #{db.escape_literal @params.collection} and
        collections.comp = games.comp and
        games.uid = collections.uid"
    else
      ""

    games = if sort == "random"
      @res\add_header "Cache-Control", "no-store"

      seed = (tonumber(@params.seed) or os.time! / 60) % 100000 / 100000
      res = db.query "
        begin;
        set local seed = ?;
        select * from (
          select *, random() from #{Games\table_name!}
            #{inner_join}
            where games.event_id = ?
        ) g
          order by g.random asc
          limit ? offset ?;
        commit
      ", seed, event.id, limit, offset

      [Games\load(g) for g in *res[3]]
    else
      Games\select "
        #{inner_join}
        where games.event_id = ?
        #{sort}
        limit ? offset ?", event.id, limit, offset

    sizes = {
      small: "220x220"
      medium: "340x340"
      large: "560x560"
    }

    thumb_size = sizes[@params.thumb_size] or sizes.medium

    for game in *games
      game.screenshot_url = game\screenshot_url @, thumb_size
      game.url = "http://ludumdare.com/compo/#{event.slug}/" .. game.url
      game.user_url = "http://ludumdare.com/compo/author/#{game.user}/"

    games = nil unless next games
    json: { games: games, count: games and #games }

  "/admin/scrape_games": =>
    import ludumdare from require "clients"

    games = ludumdare\fetch_list "ludum-dare-#{config.comp_id}"

    import gettime from require "socket"
    start = gettime!
    count = 0
    @html ->
      for game in *games
        game.comp_name = config.comp_name
        success, err = pcall ->
          g, new_record = Games\create_or_update game
          count += 1 if g

        unless success
          pre "ERR: #{game.title}: #{err}"

      pre "\n"
      pre "Games: #{count}"
      pre "Elapsed: #{gettime! - start}"

  "/admin/game/:comp/:uid/image/:image_id/:size": =>
    path = @req.parsed_url.path\match "^/admin(.*)"
    signature = image_signature path
    redirect_to: path .. "?sig=" .. signature

  "/admin/refresh_image/:uid": =>
    game = assert Games\find(comp: config.comp_name, uid: @params.uid), "missing game"
    game\load_screenshot nil, true -- update master image

    image_id = 1
    commands = for size in *{"220x220", "340x340", "560x560"}
      path = "/game/#{config.comp_name}/#{@params.uid}/image/#{image_id}/#{size}"
      cache_name = "resized_" .. ngx.md5(path) .. ".png"

      cmd = "rm cache/#{cache_name}"
      { cmd, os.execute cmd }

    json: commands

  --
  "/admin/make_collections": =>
    games = Games\select "where comp = ?", config.comp_name

    import gettime from require "socket"
    start = gettime!

    total = 0
    regexes = {}
    for collection_name, {_, words} in pairs COLLECTIONS
      regex = "\\b(?:#{table.concat words, "|"})\\b"
      filtered = search_downloads games, regex, "i"
      regexes[regex] = #filtered

      for game in *filtered
        total += 1
        Collections\add_game collection_name, config.comp_name, game

    @html ->
      pre "inserted #{total} rows"
      pre "took #{gettime! - start} sec"


