import encode_query_string from require "lapis.util"
import from_json from require "lapis.util"
cjson = require "cjson"

class LDJam extends require "clients.base"
  api_url: "https://api.ldjam.com/vx"

  handle_json_response: (res, status, label) =>
    unless status == 200
      return nil, "got bad status from #{label}: #{status}"

    local result
    pcall ->
      result = from_json res

    unless result
      return nil, "failed to parse json from #{label}"

    result

  event_game_ids: (node_id, limit=50, offset=0) =>
    params = encode_query_string { :offset, :limit }
    res, status = @http!.request "#{@api_url}/node/feed/#{event}/parent/item/game?#{params}"
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
      res, status = @http!.request "#{@api_url}/node/get/#{idstring}"
      result = @handle_json_response res, status, "fetch_objects"
      result.node

      if opts and opts.cache
        @node_cache or= {}
        for node in *result.node
          @node_cache[tostring node.id] = node

      for node in *result.node
        table.insert have, node

    have

  each_game: (event, offset=0) =>
    limit = 50

    coroutine.wrap ->
      while true
        res = assert @event_game_ids event, limit, offset
        feed = assert res.feed, "missing feed object"
        break unless next feed

        ids = [f.id for f in *feed]

        for game in *@fetch_objects ids
          coroutine.yield game

        offset += limit

{:LDJam}
