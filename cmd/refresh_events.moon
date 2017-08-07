
events = require "data.events"

import slugify from require "lapis.util"
import insert_on_conflict_update from require "helpers.model"
import Events from require "models"

for event in *events
  slug = event.slug or slugify event.name
  assert slug and slug != "", "missing slug"

  event = {k,v for k,v in pairs event}
  event.type = Events.types\for_db event.type

  insert_on_conflict_update Events, {
    :slug
  }, event



