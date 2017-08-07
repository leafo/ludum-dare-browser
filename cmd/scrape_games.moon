
-- import Games from require "models"
-- 
-- fetch_jam = (id) ->
--   import ludumdare from require "clients"
--   comp_name = "ludum-dare-#{id}"
--   games = ludumdare\fetch_list comp_name
--   return nil, "invalid comp" unless games and next games
-- 
--   for game in *games
--     game.comp_name = comp_name
--     Games\create_or_update game
-- 
--   true
-- 
-- jamid = assert ..., "missing jam id"
-- if jamid == "all"
--   for id=37,1,-1
--     print "Fetching #{id}"
--     assert fetch_jam id
-- else
--   fetch_jam jamid

import Events from require "models"

event = Events\find slug: "ludum-dare-28"
require("moon").p event
event\full_refresh!
