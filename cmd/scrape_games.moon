
event_slug, uid = ...

import Events from require "models"

unless event_slug
  for event in *Events\select!
    print "Refreshing #{event.name}"
    event\full_refresh!

  return

event = assert Events\find(slug: event_slug), "invalid event: #{event_slug}"
if uid
  print "Refreshing #{event.name} -> #{uid}"
  import Games from require "models"
  game = Games\find uid: uid, event_id: event.id
  assert game, "invalid game: #{uid}"
  res = game\fetch_details true
  require("moon").p res
else
  print "Refreshing #{event.name}"
  event\full_refresh!




