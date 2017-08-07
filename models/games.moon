db = require "lapis.db"
import Model from require "lapis.db.model"

config = require("lapis.config").get!
import to_json, from_json from require "lapis.util"

-- Generated schema dump: (do not edit)
--
-- CREATE TABLE games (
--   id integer NOT NULL,
--   comp character varying(255),
--   uid character varying(255) NOT NULL,
--   "user" text NOT NULL,
--   url character varying(255) NOT NULL,
--   title text NOT NULL,
--   downloads json,
--   num_downloads integer DEFAULT 0 NOT NULL,
--   screenshots json,
--   num_screenshots integer DEFAULT 0 NOT NULL,
--   votes_received integer DEFAULT 0 NOT NULL,
--   votes_given integer DEFAULT 0 NOT NULL,
--   is_jam boolean,
--   have_details boolean DEFAULT false NOT NULL,
--   created_at timestamp without time zone NOT NULL,
--   updated_at timestamp without time zone NOT NULL,
--   event_id integer
-- );
-- ALTER TABLE ONLY games
--   ADD CONSTRAINT games_pkey PRIMARY KEY (id);
-- CREATE INDEX games_comp_title_idx ON games USING btree (comp, title);
-- CREATE UNIQUE INDEX games_comp_uid_idx ON games USING btree (comp, uid);
-- CREATE UNIQUE INDEX games_event_id_uid_idx ON games USING btree (event_id, uid);
-- CREATE INDEX games_votes_given_idx ON games USING btree (votes_given);
-- CREATE INDEX games_votes_received_idx ON games USING btree (votes_received);
--
class Games extends Model
  @timestamp: true

  @simple_fields = {
    "url", "title", "uid", "user", "votes_received", "votes_given", "is_jam",
    "have_details"
  }

  @relations: {
    {"event", belongs_to: "Events"}
  }

  @create_from_ludumdare: (event, data, additional_data) =>
    import insert_on_conflict_update, filter_update from require "helpers.model"

    data = {k,v for k,v in pairs data}
    if additional_data
      for k,v in pairs additional_data
        data[k] = v

    primary = {
      event_id: event.id
      uid: assert data.uid, "missing uuid"
    }

    array_fields = {"downloads", "screenshots"}

    update = {k, data[k] for k in *@simple_fields}

    for field in *array_fields
      continue unless data[field]
      update[field] = data[field]
      update["num_#{field}"] = #(data[field] or {})

    -- see if there were actually any changes
    if existing = @find primary
      test_update = filter_update existing, {k,v for k,v in pairs update}
      return nil, "already updated" unless next test_update

    for field in *array_fields
      continue unless update[field]
      update[field] = next(update[field]) and to_json(update[field]) or db.NULL

    insert_on_conflict_update @, primary, update

  fetch_details: (force=false)=>
    return if @have_details and not force
    event = @get_event!
    return nil, "invalid type" unless event\is_ludumdare!

    client = event\get_client!
    data, raw_page = client\fetch_game(@uid, event.slug)

    screenshots = data.screenshots or {}

    @update {
      num_screenshots: #screenshots
      screenshots: next(screenshots) and to_json(screenshots) or db.NULL
      is_jam: data.is_jam
      have_details: true
    }

    import GameData from require "models"
    GameData\create {
      game_id: @id
      data: {
        page: raw_page
      }
    }

    @refresh!
    @

  get_comp_slug: =>
    if @event_id
      @get_event!.slug
    else
      @comp

  fetch_screenshots: =>
    unless @screenshots
      @fetch_details!

    @screenshots

  load_screenshot: (i=1, skip_cache=false) =>
    screens = @fetch_screenshots!
    return nil, "no screenshots" unless screens

    original_url = screens[i]
    return nil, "invalid screenshot" unless original_url

    ext = original_url\match("%.%w+$") or ""
    raw_ext = ext\match"%w+"
    cache_name = ngx.md5(original_url) .. ext

    local image_blob, cache_hit
    file = io.open "cache/#{cache_name}"
    if file and not skip_cache
      cache_hit = true
      image_blob = file\read "*a"
      file\close!
    else
      cache_hit = false
      http = require "lapis.nginx.http"
      image_blob, status = http.request original_url
      unless status == 200
        return nil, "failed to fetch original"

      with io.open "cache/#{cache_name}", "w"
        \write image_blob
        \close!

    image_blob, raw_ext, cache_hit

  -- gets the nth screenshot
  screenshot_url: (r, size, image_id=1) =>
    if size
      import image_signature from require "helpers.image_signature"
      path = r\url_for "screenshot_sized", game_id: @id, :image_id, :size
      path .. "?sig=" .. image_signature path
    else
      r\url_for "screnshot_raw", game_id: @id, :image_id
