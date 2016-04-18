lapis = require "lapis"
http = require "lapis.nginx.http"

game_list = require "game_list"
game_list.set_http http

import to_json from require "lapis.util"
json = require "cjson"

COMP_NAME = "ludum-dare-35"
COMP_ID = 35

db = require "lapis.db"
import Model from require "lapis.db.model"
import respond_to from require "lapis.application"

local *

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

image_signature = do
  for_url = (str) ->
    (str\gsub "[/+]", {
      "+": "%2B"
      "/": "%2F"
    })

  (path, _url=true, len=10, secret=require"secret.keys".image_key) ->
    str = ngx.encode_base64 ngx.hmac_sha1 secret, path
    str = str\sub 1, len if len
    str = for_url str if _url
    str


cached = (dict_name, fn) ->
  unless type(fn) == "function"
    fn = dict_name
    dict_name = "page_cache"

  =>
    params = [k.. ":" .. v for k,v in pairs @GET]
    table.sort params
    params = table.concat params, "-"
    cache_key = @req.parsed_url.path .. "#" .. params

    dict = ngx.shared[dict_name]

    if cache_value = dict\get cache_key
      ngx.header["x-memory-cache-hit"] = "1"
      cache_value = json.decode(cache_value)
      return cache_value

    old_render = @render
    @render = (...) =>
      old_render @, ...
      -- this is done like this because you can't mix hash/array in json
      to_cache = json.encode {
        {
          content_type: @res.headers["Content-type"]
          layout: false -- layout is already part of content
        }
        @res.content
      }
      dict\set cache_key, to_cache
      ngx.header["x-memory-cache-save"] = "1"
      nil

    fn @

-- eg. search for love games:
-- love_games = search_downloads("\\blove\\b", "i")
search_downloads = (games=Games\select!, ...) ->
  match = ngx.re.match

  found = {}
  for game in *games
    if type(game.downloads) == "string"
      game.downloads = json.decode game.downloads

    for d in *game.downloads
      if match(d.href, ...) or match(d.label, ...)
        table.insert found, game
        break

  found

class Games extends Model
  @timestamp: true

  @simple_columns = {
    "url", "title", "uid", "user", "votes_received", "votes_given", "is_jam",
    "have_details"
  }

  @create_or_update: (data, game=nil) =>
    game = game or @find comp: COMP_NAME, uid: data.uid
    formatted = {k, data[k] for k in *@simple_columns}

    if downloads = data.downloads
      formatted.downloads = to_json downloads
      formatted.num_downloads = #downloads

    if screenshots = data.screenshots
      formatted.screenshots = to_json screenshots
      formatted.num_screenshots = #screenshots

    if game
      for k,v in pairs formatted
        formatted[k] = nil if v == game[k]

      game\update formatted
      game, false
    else
      formatted.comp = COMP_NAME
      @create(formatted), true

  fetch_details: (force=false)=>
    return if @have_details and not force
    detailed = game_list.fetch_game @uid, COMP_ID
    detailed.have_details = true
    @@create_or_update detailed, @

  parse_screenshots: =>
    @fetch_details!
    return nil unless @num_screenshots > 0 and @screenshots
    json.decode @screenshots

  load_screenshot: (i=1, skip_cache=false) =>
    screens = @parse_screenshots!
    return nil, "no screenshots" unless screens

    original_url = screens[i]
    return nil, "invalid screenshot" unless original_url

    ext = original_url\match("%.%w+$") or ""
    raw_ext = ext\match"%w+"
    cache_name = ngx.md5(original_url) .. ext

    local image_blob, cache_hit
    file = io.open "cache/#{cache_name}"
    if file and not skip_cache
      cache_hit = true
      image_blob = file\read "*a"
      file\close!
    else
      cache_hit = false
      image_blob, status = http.request original_url
      unless status == 200
        return nil, "failed to fetch original"

      with io.open "cache/#{cache_name}", "w"
        \write image_blob
        \close!

    image_blob, raw_ext, cache_hit

  screenshot_url: (r, size, image_id=1) =>
    if size
      path = r\url_for "screenshot_sized", comp: @comp, uid: @uid, :image_id, :size
      path .. "?sig=" .. image_signature path
    else
      r\url_for "screnshot_raw", comp: @comp, uid: @uid, :image_id


class Collections extends Model
  @primary_key: {"name", "comp", "uid"}

  @add_game: (name, comp, game) =>
    uid = game.uid
    params = { :name, :comp, :uid }
    unless @find params
      @create params

class LudumDare extends lapis.Application
  "/game/:comp/:uid": =>
    game = Games\find comp: @params.comp, uid: @params.uid
    return status: 404 unless game

    game\fetch_details!
    json: game

  [screenshot_sized: "/game/:comp/:uid/image/:image_id/:size"]: =>
    image_id = tonumber(@params.image_id) or 1

    signature = image_signature @req.parsed_url.path, false
    if @params.sig != signature
      return status: 403, "invalid signature"

    game = Games\find comp: @params.comp, uid: @params.uid
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
  [screnshot_raw: "/game/:comp/:uid/image/:image_id"]: =>
    image_id = tonumber(@params.image_id) or 1
    game = Games\find comp: @params.comp, uid: @params.uid
    return status: 404, "missing game" unless game

    image_blob, ext_or_err, cache_hit = game\load_screenshot image_id
    return status: 404, ext_or_err unless image_blob

    ngx.header["x-image-cache"] = cache_hit and "hit" or "miss"
    content_type: CONTENT_TYPES[ext_or_err], layout: false, image_blob

  "/games": cached =>
    page = tonumber(@params.page) or 0
    limit = 40
    offset = page * limit

    sorts = {
      votes: "order by votes_received desc, votes_given desc, title asc"
      votes_reverse: "order by votes_received asc, votes_given desc, title desc"

      coolness: "order by votes_given desc, votes_received asc, title asc"
      coolness_reverse: "order by votes_given asc, votes_received desc, title desc"
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

    games = Games\select "
      #{inner_join}
      where games.comp = ?
      #{sort}
      limit ? offset ?", COMP_NAME, limit, offset

    sizes = {
      small: "220x220"
      medium: "340x340"
      large: "560x560"
    }
    thumb_size = sizes[@params.thumb_size] or sizes.medium

    for game in *games
      game.downloads = json.decode game.downloads
      game.screenshot_url = game\screenshot_url @, thumb_size
      game.url = "http://ludumdare.com/compo/#{game.comp}/" .. game.url
      game.user_url = "http://ludumdare.com/compo/author/#{game.user}/"

    games = nil unless next games
    json: { games: games, count: games and #games }

  "/admin/scrape_games": =>
    games = game_list.fetch_list COMP_ID

    import gettime from require "socket"
    start = gettime!
    count = 0
    @html ->
      for game in *games
        success, err = pcall ->
          g, new_record = Games\create_or_update game
          count += 1 if g

        unless success
          pre "ERR: #{game.title}: #{err}"

      pre "\n"
      pre "Games: #{count}"
      pre "Elapsed: #{gettime! - start}"

  [cache: "/admin/cache"]: respond_to {
    GET: =>
      dict = ngx.shared.page_cache
      keys = dict\get_keys()
      table.sort keys

      sum = 0
      @html ->
        ul ->
          for key in *keys
            li ->
              kb = #dict\get(key) / 1014
              sum += kb
              code key
              text " "
              span "%.2f"\format(kb) .. "kb"

        div ->
          b "total: "
          text "%.2f"\format(sum)
          text "kb"

        form method: "POST", -> button "Purge"

    POST: =>
      ngx.shared.page_cache\flush_all!
      redirect_to: @url_for "cache"
  }

  "/admin/game/:comp/:uid/image/:image_id/:size": =>
    path = @req.parsed_url.path\match "^/admin(.*)"
    signature = image_signature path
    redirect_to: path .. "?sig=" .. signature

  "/admin/refresh_image/:uid": =>
    game = assert Games\find(comp: COMP_NAME, uid: @params.uid), "missing game"
    game\load_screenshot nil, true -- update master image

    image_id = 1
    commands = for size in *{"220x220", "340x340", "560x560"}
      path = "/game/#{COMP_NAME}/#{@params.uid}/image/#{image_id}/#{size}"
      cache_name = "resized_" .. ngx.md5(path) .. ".png"

      cmd = "rm cache/#{cache_name}"
      { cmd, os.execute cmd }

    json: commands

  --
  "/admin/make_collections": =>
    games = Games\select "where comp = ?", COMP_NAME

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
        Collections\add_game collection_name, COMP_NAME, game

    @html ->
      pre "inserted #{total} rows"
      pre "took #{gettime! - start} sec"


