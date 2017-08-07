
db = require "lapis.db.postgres"
schema = require "lapis.db.schema"

import create_table, create_index, drop_table, add_column from schema

{
  :boolean, :varchar, :integer, :text, :foreign_key, :double, :time, :numeric, :serial, :enum
} = schema.types

{
  [1]: =>
    create_table "games", {
      {"id", serial}
      {"comp", varchar}
      {"uid", varchar}
      {"user", varchar}
      {"url", varchar}

      {"title", varchar}

      {"downloads", text}
      {"num_downloads", integer}

      {"screenshots", text null: true}
      {"num_screenshots", integer}

      {"votes_received", integer}
      {"votes_given", integer}

      {"is_jam", boolean default: db.NULL, null: true}
      {"have_details", boolean default: false}

      {"created_at", time}
      {"updated_at", time}

      "PRIMARY KEY(id)"
    }

    create_index "games", "comp", "uid", unique: true
    create_index "games", "comp", "title"

    create_index "games", "votes_received"
    create_index "games", "votes_given"

    create_table "collections", {
      {"name", varchar}
      {"comp", varchar}
      {"uid", varchar}

      "PRIMARY KEY(name, comp, uid)"
    }

  [2]: =>
    db.query "alter table games alter column title type text"
    db.query 'alter table games alter column "user" type text'

  [3]: =>
    create_table "events", {
      {"id", serial}
      {"slug", varchar null: true}
      {"type", enum}
      {"key", varchar null: true}
      {"name", text}

      {"start_date", time null: true}
      {"end_date", time null: true}

      {"created_at", time}
      {"updated_at", time}

      "PRIMARY KEY(id)"
    }

    create_index "events", "slug", unique: true

    add_column "games", "event_id", foreign_key null: true

    create_table "game_data", {
      {"game_id", serial}
      {"data", "json"}
      "PRIMARY KEY (game_id)"
    }

  [4]: =>
     db.query "alter table games alter column downloads drop not null"
     db.query "alter table games alter column downloads type json using downloads::json"
     db.query "alter table games alter column screenshots type json using screenshots::json"

  [5]: =>
    create_index "games", "event_id", "uid", unique: true
    db.query "alter table games alter column comp drop not null"

  [6]: =>
    add_column "events", "games_count", integer null: true, default: db.NULL
    add_column "events", "last_refreshed_at", time null: true

  [7]: =>
    drop_table "collections"

    create_table "collection_games", {
      {"name", varchar}
      {"event_id", foreign_key}
      {"game_id", foreign_key}

      "PRIMARY KEY(name, game_id)"
    }

    create_index "collection_games", "event_id", "name"
    create_index "collection_games", "game_id"

  [8]: =>
    add_column "games", "user_url", varchar null: true

}

