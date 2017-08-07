import Model from require "lapis.db.model"

config = require("lapis.config").get!
import to_json, from_json from require "lapis.util"

-- Generated schema dump: (do not edit)
--
-- CREATE TABLE games (
--   id integer NOT NULL,
--   comp character varying(255) NOT NULL,
--   uid character varying(255) NOT NULL,
--   "user" character varying(255) NOT NULL,
--   url character varying(255) NOT NULL,
--   title character varying(255) NOT NULL,
--   downloads text NOT NULL,
--   num_downloads integer DEFAULT 0 NOT NULL,
--   screenshots text,
--   num_screenshots integer DEFAULT 0 NOT NULL,
--   votes_received integer DEFAULT 0 NOT NULL,
--   votes_given integer DEFAULT 0 NOT NULL,
--   is_jam boolean,
--   have_details boolean DEFAULT false NOT NULL,
--   created_at timestamp without time zone NOT NULL,
--   updated_at timestamp without time zone NOT NULL
-- );
-- ALTER TABLE ONLY games
--   ADD CONSTRAINT games_pkey PRIMARY KEY (id);
-- CREATE INDEX games_comp_title_idx ON games USING btree (comp, title);
-- CREATE UNIQUE INDEX games_comp_uid_idx ON games USING btree (comp, uid);
-- CREATE INDEX games_votes_given_idx ON games USING btree (votes_given);
-- CREATE INDEX games_votes_received_idx ON games USING btree (votes_received);
--
class Games extends Model
  @timestamp: true

  @simple_columns = {
    "url", "title", "uid", "user", "votes_received", "votes_given", "is_jam",
    "have_details"
  }

  @create_or_update: (data, game=nil) =>
    game = game or @find {
      comp: assert(data.comp_name, "missing comp_name from data")
      uid: data.uid
    }

    formatted = {k, data[k] for k in *@simple_columns}

    if downloads = data.downloads
      formatted.downloads = to_json downloads
      formatted.num_downloads = #downloads

    if screenshots = data.screenshots
      formatted.screenshots = to_json screenshots
      formatted.num_screenshots = #screenshots

    if game
      for k,v in pairs formatted
        formatted[k] = nil if v == game[k]

      game\update formatted
      game, false
    else
      formatted.comp = data.comp_name
      @create(formatted), true

  fetch_details: (force=false)=>
    return if @have_details and not force
    import ludumdare from require "clients"

    detailed = ludumdare\fetch_game @uid, assert @get_comp_id!
    detailed.have_details = true
    @@create_or_update detailed, @

  get_comp_id: =>
    @comp\match "^ludum%-dare%-(%d+)$"

  parse_screenshots: =>
    @fetch_details!
    return nil unless @num_screenshots > 0 and @screenshots
    from_json @screenshots

  load_screenshot: (i=1, skip_cache=false) =>
    screens = @parse_screenshots!
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

  screenshot_url: (r, size, image_id=1) =>
    if size
      import image_signature from require "helpers.image_signature"
      path = r\url_for "screenshot_sized", comp: @comp, uid: @uid, :image_id, :size
      path .. "?sig=" .. image_signature path
    else
      r\url_for "screnshot_raw", comp: @comp, uid: @uid, :image_id
