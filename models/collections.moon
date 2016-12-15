import Model from require "lapis.db.model"

-- Generated schema dump: (do not edit)
--
-- CREATE TABLE collections (
--   name character varying(255) NOT NULL,
--   comp character varying(255) NOT NULL,
--   uid character varying(255) NOT NULL
-- );
-- ALTER TABLE ONLY collections
--   ADD CONSTRAINT collections_pkey PRIMARY KEY (name, comp, uid);
--
class Collections extends Model
  @primary_key: {"name", "comp", "uid"}

  @add_game: (name, comp, game) =>
    uid = game.uid
    params = { :name, :comp, :uid }
    unless @find params
      @create params
