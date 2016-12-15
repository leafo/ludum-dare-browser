
db = require "lapis.db.postgres"
schema = require "lapis.db.schema"

import create_table, create_index, drop_table from schema

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
}

