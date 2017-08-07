import encode_query_string from require "lapis.util"
import from_json from require "lapis.util"
cjson = require "cjson"

class LDJam extends require "clients.base"
  api_url: "https://api.ldjam.com/vx"

  events: {
    ld39: 32802
  }

  handle_json_response: (res, status, label) =>
    unless status == 200
      return nil, "got bad status from #{label}: #{status}"

    local result
    pcall ->
      result = from_json res

    unless result
      return nil, "failed to parse json from #{label}"

    result

  event_game_ids: (event, limit=50, offset=0) =>
    node_id = @events[event] or event
    params = encode_query_string { :offset, :limit }
    res, status = @http!.request "#{@api_url}/node/feed/#{event}/all/item/game?#{params}"
    @handle_json_response res, status, "event_game_ids"

  fetch_game: (id) =>
    unpack @fetch_games {id}

  -- bulk fetch games by id
  fetch_games: (ids) =>
    idstring = table.concat ids, "+"
    res, status = @http!.request "#{@api_url}/node/get/#{idstring}"
    result = @handle_json_response res, status, "fetch_games"
    result.node

  each_game: (event, offset=0) =>
    limit = 50

    coroutine.wrap ->
      while true
        res = assert @event_game_ids event, limit, offset
        feed = assert res.feed, "missing feed object"
        break unless next feed

        ids = [f.id for f in *feed]

        for game in *@fetch_games ids
          coroutine.yield game

        offset += limit

{:LDJam}
