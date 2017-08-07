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
--   updated_at timestamp without time zone NOT NULL
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

  @create: (opts) =>
    super opts


