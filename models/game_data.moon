db = require "lapis.db"
import Model from require "lapis.db.model"

import to_json from require "lapis.util"

-- Generated schema dump: (do not edit)
--
-- CREATE TABLE game_data (
--   game_id integer NOT NULL,
--   data json
-- );
-- ALTER TABLE ONLY game_data
--   ADD CONSTRAINT game_data_pkey PRIMARY KEY (game_id);
--
class GameData extends Model
  @primary_key: "game_id"

  @create: (opts) =>
    import insert_on_conflict_update from require "helpers.model"

    update = {k,v for k,v in pairs opts}
    update.game_id = nil

    update.data = next(update.data) and to_json(update.data) or db.NULL

    insert_on_conflict_update @, {
      game_id: opts.game_id
    }, update


