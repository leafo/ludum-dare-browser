lapis = require "lapis"
db = require "lapis.db"
config = require("lapis.config").get!

import Games, Events, CollectionGames from require "models"
import preload from require "lapis.db.model"
import respond_to, capture_errors_json, assert_error from require "lapis.application"
import image_signature from require "helpers.image_signature"
import assert_valid from require "lapis.validate"

THUMB_SIZES = {
  small: "220x220"
  medium: "340x340"
  large: "560x560"
}


CONTENT_TYPES = {
  jpg: "image/jpeg"
  png: "image/png"
  gif: "image/gif"
}

class LudumDare extends lapis.Application
  dispatch: (r, ...) =>
    r.parsed_url.path = ngx.var.uri -- allow subrequest path to get sent down
    super r, ...

  "/game/:event_slug/:uid": =>
    event = Events\find slug: @params.event_slug
    return "invalid event", status: 404 unless event

    game = Games\find event_id: event.id, uid: @params.uid
    return "invalid game", status: 404 unless game

    game\fetch_details!
    json: game

  -- this is cached by nginx
  [screenshot_sized: "/game/:game_id/image/:image_id/:size"]: =>
    image_id = tonumber(@params.image_id) or 1

    signature = image_signature @req.parsed_url.path
    if @params.sig != signature
      return status: 403, "invalid signature"

    game = Games\find @params.game_id
    return status: 404, "missing game" unless game

    blob, err_or_ext = game\load_screenshot image_id
    return status: 404, err_or_ext unless blob

    -- bail on gif, we don't know how to resize
    if err_or_ext\lower! == "gif"
      return content_type: CONTENT_TYPES.gif, layout: false, blob

    magick = require "magick.gmwand"
    img = magick.load_image_from_blob blob
    img\set_format "png"
    size = @params.size
    -- handle tall images differently
    ar = img\get_width! / img\get_height!
    if ar > 2 or 1/ar > 2
      size = size .. "#"

    resized_blob = magick.thumb img, size
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

  "/events": capture_errors_json =>
    events = Events\select "order by slug desc"
    json: {
      default_event: "ludum-dare-#{config.comp_id}"
      events: [@flow("formatter")\event e for e in *events]
    }

  "/stats/events": capture_errors_json =>
    -- total
    event_votes = db.query "select id, slug, name,
      coalesce((select sum(votes_received) from games where games.event_id = events.id), 0) as total_votes
      from events
      order by slug desc"

    for row in *event_votes
      row.short_name = Events.short_name { name: row.name }

    -- top users
    top_users_submissions = db.query [[
      select
        games."user",
        count(*) submissions_count,
        sum(votes_given) votes_given,
        sum(votes_received) votes_received,
        min(events.slug) as first_seen,
        max(events.slug) as last_seen
      from games
      inner join events on events.id = games.event_id
      where "user" is not null
      group by 1 order by 2 desc limit 30
    ]]

    top_users_votes_given = db.query [[
      select
        "user",
        sum(votes_given) votes_given,
        sum(votes_received) votes_received
      from games
      where "user" is not null
      group by 1 order by 2 desc limit 30
    ]]

    top_users_votes_received = db.query [[
      select
        "user",
        sum(votes_received) votes_received,
        sum(votes_given) votes_given
      from games
      where "user" is not null
      group by 1 order by 2 desc limit 30
    ]]

    json: {
      generated_at: db.format_date!
      :event_votes
      :top_users_submissions
      :top_users_votes_received
      :top_users_votes_given
    }

  "/events/:event_slug": capture_errors_json =>
    event = Events\find slug: @params.event_slug
    assert_error event, "invalid event"
    json: {
      event: @flow("formatter")\event event
    }

  "/search/games": capture_errors_json =>
    assert_valid @params, {
      {"q", exists: true, type: "string"}
    }

    query = @params.q

    page = tonumber(@params.page) or 0
    limit = 40
    offset = page * limit

    games = Games\select [[
      inner join events on events.id = event_id
      where title % ? or "user" % ?
      order by greatest(similarity(title, ?), similarity("user", ?)) desc, events.slug desc
      limit ? offset ?
    ]], query, query, query, query, limit, offset, {
      fields: "games.*"
    }

    preload games, "event"

    thumb_size = THUMB_SIZES[@params.thumb_size] or THUMB_SIZES.medium
    formatted_games = [@flow("formatter")\game g, thumb_size for g in *games]

    json: {
      games: next(formatted_games) and formatted_games or nil
    }


  "/users/:username/games": capture_errors_json =>
    @res\add_header "Cache-Control", "no-store"

    page = tonumber(@params.page) or 0
    limit = 40
    offset = page * limit

    username = @params.username\lower!

    games = Games\select [[
      inner join events on events.id = event_id
      where "user" % ? and lower("user") = ?
      order by events.slug desc
      limit ? offset ?
    ]], username, username, limit, offset, {
      fields: "games.*"
    }

    preload games, "event"

    thumb_size = THUMB_SIZES[@params.thumb_size] or THUMB_SIZES.medium
    formatted_games = [@flow("formatter")\game g, thumb_size for g in *games]

    json: {
      games: next(formatted_games) and formatted_games or nil
    }

  "/games/:event_slug": capture_errors_json =>
    event = Events\find slug: @params.event_slug

    assert_error event, "invalid event"

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
    import COLLECTIONS from CollectionGames
    inner_join = if collection and COLLECTIONS[collection]
      db.interpolate_query "
        inner join collection_games cgs on
          cgs.name = #{db.escape_literal @params.collection} and
          cgs.game_id = games.id and
          cgs.event_id = ?
      ", event.id
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

    preload games, "event"

    thumb_size = THUMB_SIZES[@params.thumb_size] or THUMB_SIZES.medium

    fields = {
      "id", "downloads", "title", "votes_given", "votes_received", "is_jam", "user", "uid", "screenshots"
    }

    formatted = for game in *games
      @flow("formatter")\game game, thumb_size

    formatted = nil unless next formatted
    json: { games: formatted, count: formatted and #formatted }

  "/admin/scrape_games": =>
    event_slug = @params.event_slug or "ludum-dare-#{config.comp_id}"

    events = if event_slug != "all"
      {(assert Events\find(slug: event_slug), "invalid event: #{event_slug}")}
    else
      Events\select!

    import gettime from require "socket"
    start = gettime!
    for event in *events
      event\full_refresh!

    json: {
      events: {e.slug, e.games_count for e in *events}
      time_taken: gettime! - start
    }

  "/admin/refresh_image/:game_id": =>
    game = assert Games\find(@params.game_id), "missing game"
    game\load_screenshot nil, true -- update master image

    -- TODO: purge image cache
    json: {}

  --
  "/admin/make_collections": =>
    event_slug = @params.event_slug or "ludum-dare-#{config.comp_id}"

    events = if event_slug != "all"
      {(assert Events\find(slug: event_slug), "invalid event: #{event_slug}")}
    else
      Events\select!

    import gettime from require "socket"
    start = gettime!

    for event in *events
      event\refresh_collections!

    counts = db.query "
      select name, count(*) from #{db.escape_identifier CollectionGames\table_name!} where event_id in ? group by 1
    ", db.list [e.id for e in *events]

    counts = {row.name, row.count for row in *counts}

    json: {
      events: [event.name for event in *events]
      time_taken: gettime! - start
      :counts
    }

  -- routed by nginx
  [home: "/"]: =>
  [event: "/jam/:slug"]: =>
