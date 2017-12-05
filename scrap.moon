

-- import LDJam from require "clients.ldjam"
-- 
-- client = LDJam!
-- games = 0
-- for game in client\each_game!
--   games += 1
--   print games

import Events, Games from require "models"

g = Games\find 55135
event = g\get_event!

client = event\get_client!

-- require("moon").p client\fetch_platforms!

game = client\fetch_object g.uid
Games\create_from_ldjam event, game

-- require("moon").p game
-- 
-- -- require("moon").p {
-- --   Games\create_from_ldjam event, game
-- -- }

