
import Games from require "models"

fetch_jam = (id) ->
  import fetch_list from require "game_list"
  comp_name = "ludum-dare-#{id}"
  games = fetch_list id
  return nil, "invalid comp" unless games and next games

  for game in *games
    game.comp_name = comp_name
    Games\create_or_update game

  true

jamid = assert ..., "missing jam id"
if jamid == "all"
  for id=37,1,-1
    print "Fetching #{id}"
    assert fetch_jam id
else
  fetch_jam jamid
