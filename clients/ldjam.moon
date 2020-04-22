import encode_query_string from require "lapis.util"
import from_json from require "lapis.util"
cjson = require "cjson"

class LDJam extends require "clients.base"
  api_url: "https://api.ldjam.com/vx"

  purge_cache: =>
    @node_cache = nil

  request: (...) =>
    @http!.request ...

  trim_nulls: (obj) =>
    {k, v for k, v in pairs obj when v != cjson.null}

  handle_json_response: (res, status, label) =>
    unless status == 200
      return nil, "got bad status from #{label}: #{status}"

    local result
    pcall ->
      result = from_json res

    result = @trim_nulls result

    unless result
      return nil, "failed to parse json from #{label}"

    result

  event_game_ids: (node_id, limit=50, offset=0) =>
    params = encode_query_string { :offset, :limit }
    res, status = @request "#{@api_url}/node/feed/#{node_id}/parent/item/game?#{params}"
    @handle_json_response res, status, "event_game_ids"

  fetch_object: (id, ...) =>
    unpack @fetch_objects {id}, ...

  -- bulk fetch objects by id, optionally hitting cache
  fetch_objects: (ids, opts) =>
    have = {}
    dont_have = {}

    for id in *ids
      id = tostring id

      if node = @node_cache and @node_cache[id]
        table.insert have, node
      else
        table.insert dont_have, id

    if next dont_have
      idstring = table.concat dont_have, "+"
      url = "#{@api_url}/node/get/#{idstring}"
      res, status = @request "#{@api_url}/node/get/#{idstring}"
      result = assert @handle_json_response res, status, "fetch_objects: #{url}"

      if opts and opts.cache
        @node_cache or= {}
        for node in *result.node
          @node_cache[tostring node.id] = node

      for node in *result.node
        table.insert have, node

    have

  each_game: (event, opts={}) =>
    limit = opts.per_page or 10
    offset = opts.offset or 0

    coroutine.wrap ->
      while true
        res = assert @event_game_ids event, limit, offset
        feed = assert res.feed, "missing feed object"
        break unless next feed

        ids = [f.id for f in *feed]

        games = @fetch_objects ids

        if opts.preload_authors
          @fetch_objects [g.author for g in *games], cache: true

        for game in *games
          coroutine.yield game

        offset += limit

  fetch_platforms: =>
    res, status = assert @request "#{@api_url}/tag/get/platform"
    @handle_json_response res, status, "fetch_objects"

{:LDJam}
