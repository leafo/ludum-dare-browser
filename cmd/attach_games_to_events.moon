

db = require "lapis.db"

import Events, Games from require "models"

for event in *Events\select!
  res = db.update Games\table_name!, {
    event_id: event.id
  }, {
    comp: event.slug
    event_id: db.NULL
  }

  print event.slug, res.affected_rows

