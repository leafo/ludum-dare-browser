lapis = require "lapis"
http = require "lapis.nginx.http"

game_list = require "game_list"
game_list.set_http http

import to_json from require "lapis.util"
json = require "cjson"

COMP_NAME = "ludum-dare-26"

import Model from require "lapis.db.model"

b64_for_url = (str, len)->
  str = ngx.encode_base64 str
  str = str\sub 1, len if len
  (str\gsub "[/+]", {
    "+": "%2B"
    "/": "%2F"
  })

image_signature = (path, secret=require"secret.keys".image_key) ->
  b64_for_url ngx.hmac_sha1(secret, path), 10

content_types = {
  jpg: "image/jpeg"
  png: "image/png"
  gif: "image/gif"
}

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
    detailed = game_list.fetch_game @uid
    detailed.have_details = true
    @@create_or_update detailed, @

  parse_screenshots: =>
    @fetch_details!
    return nil unless @num_screenshots > 0 and @screenshots
    json.decode @screenshots

  load_screenshot: (i=1)=>
    screens = @parse_screenshots!
    return nil, "no screenshots" unless screens

    original_url = screens[i]
    return nil, "invalid screenshot" unless original_url

    ext = original_url\match("%.%w+$") or ""
    raw_ext = ext\match"%w+"
    cache_name = ngx.md5(original_url) .. ext

    local image_blob, cache_hit
    if file = io.open "cache/#{cache_name}"
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

class LudumDare extends lapis.Application
  "/gen_sig/game/:comp/:uid/image/:image_id/:size": =>
    path = @req.parsed_url.path\match "^/gen_sig(.*)"
    signature = image_signature path
    redirect_to: path .. "?sig=" .. signature

  "/db/make": =>
    schema = require "schema"
    schema.make_schema!
    json: { status: "ok" }

  "/db/migrate": =>
    import run_migrations from require "lapis.db.migrations"
    run_migrations require "migrations"
    json: { status: "ok" }

  "/game/:comp/:uid": =>
    game = Games\find comp: @params.comp, uid: @params.uid
    return status: 404 unless game

    game\fetch_details!
    json: game

  [screenshot_sized: "/game/:comp/:uid/image/:image_id/:size"]: =>
    magick = require "magick"
    image_id = tonumber(@params.image_id) or 1

    signature = image_signature @req.parsed_url.path
    if @params.sig != signature
      return status: 403, "invalid signature"

    game = Games\find comp: @params.comp, uid: @params.uid
    return status: 404, "missing game" unless game

    cache_name = ngx.md5(@req.parsed_url.path) .. ".png"

    blob, err = game\load_screenshot image_id
    return status: 404, err unless blob

    img = magick.load_image_from_blob blob
    img\set_format "png"
    resized_blob = magick.thumb img, @params.size

    with io.open "cache/#{cache_name}", "w"
      \write resized_blob
      \close!

    ngx.header["x-image-cache"] = "miss"
    content_type: content_types["png"], layout: false, resized_blob

  -- get the raw image cached on our side
  [screnshot_raw: "/game/:comp/:uid/image/:image_id"]: =>
    image_id = tonumber(@params.image_id) or 1
    game = Games\find comp: @params.comp, uid: @params.uid
    return status: 404, "missing game" unless game

    image_blob, ext_or_err, cache_hit = game\load_screenshot image_id
    return status: 404, ext_or_err unless image_blob

    ngx.header["x-image-cache"] = cache_hit and "hit" or "miss"
    content_type: content_types[ext_or_err], layout: false, image_blob

  "/games": =>
    page = tonumber(@params.page) or 0
    limit = 10
    offset = page * limit
    games = Games\select "
      where comp = ?
      order by votes_received desc
      limit ? offset ?", COMP_NAME, limit, offset

    for game in *games
      game.downloads = json.decode game.downloads
      game.screenshot_url = game\screenshot_url @-- , "340x340"

    games = nil unless next games
    json: { games: games }

  "/scrape_games": =>
    require "moon"
    games = game_list.fetch_list!
    -- g, new_record = Games\create_or_update games[1]

    import gettime from require "socket"
    start = gettime!
    @html ->
      for game in *games
        g, new_record = Games\create_or_update game
        pre "#{new_record}\t#{g.title}" if g

      pre "\n"
      pre "Elapsed: #{gettime! - start}"


  "/": => "hello"
