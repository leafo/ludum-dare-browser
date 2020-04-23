db = require "lapis.db"
import Model, enum, preload from require "lapis.db.model"

-- Generated schema dump: (do not edit)
--
-- CREATE TABLE events (
--   id integer NOT NULL,
--   slug character varying(255),
--   type smallint NOT NULL,
--   key character varying(255),
--   name text NOT NULL,
--   start_date timestamp without time zone,
--   end_date timestamp without time zone,
--   created_at timestamp without time zone NOT NULL,
--   updated_at timestamp without time zone NOT NULL,
--   games_count integer,
--   last_refreshed_at timestamp without time zone
-- );
-- ALTER TABLE ONLY events
--   ADD CONSTRAINT events_pkey PRIMARY KEY (id);
-- CREATE UNIQUE INDEX events_slug_idx ON events USING btree (slug);
--
class Events extends Model
  @timestamp: true

  @types: enum {
    ludumdare: 1 -- old style
    ldjam: 2 -- new style
  }

  @relations: {
    {"games", has_many: "Games"}
    {"collection_games", has_many: "CollectionGames"}
  }

  @create: (opts) =>
    opts.type = @types\for_db opts.type
    super opts

  is_ludumdare: => @type == @@types.ludumdare
  is_ldjam: => @type == @@types.ldjam

  -- refresh all the games and data
  full_refresh: =>
    import Games from require "models"
    client = @get_client!

    switch @type
      when @@types.ludumdare
        games = client\fetch_list @key or @slug

        for game in *games
          Games\create_from_ludumdare @, game

        @update {
          last_refreshed_at: db.raw "now() at time zone 'utc'"
          games_count: #games
        }

      when @@types.ldjam
        count = 0
        key = assert @key, "missing event id"
        for game in client\each_game key, preload_authors: true, per_page: 100
          Games\create_from_ldjam @, game
          count += 1

        @update {
          last_refreshed_at: db.raw "now() at time zone 'utc'"
          games_count: count
        }

        client\purge_cache!

    -- don't let authors stick around
    if ngx
      @refresh_collections!

    true

  refresh_collections: =>
    games = @get_games!
    preload games, "collection_games"

    for game in *games
      game\refresh_collections!

  summarize_collections: =>
    import CollectionGames from require "models"
    counts = db.query "
      select name, count(*)
      from #{db.escape_identifier CollectionGames\table_name!}
      where event_id = ? group by 1
    ", @id

  get_client: =>
    switch @type
      when @@types.ludumdare
        require("clients").ludumdare
      when @@types.ldjam
        require("clients").ldjam
      else
        error "no client"

  short_name: =>
    num = @name\match "(%d+)$"
    "LD#{num}"

  url_params: =>
    config = require"lapis.config".get!
    if "ludum-dare-#{config.comp_id}" == @slug
      "home"
    else
      "event", slug: @slug

