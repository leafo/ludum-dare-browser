
import Games from require "models"

fetch_jam = (id) ->
  import fetch_list from require "game_list"
  comp_name = "ludum-dare-#{id}"
  games = fetch_list id
  for game in *games
    Games\create_or_update game

jamid = assert ..., "missing jam id"
fetch_jam jamid
