
event_slug, uid = ...

import Events from require "models"

events = switch event_slug
  when nil -- use the default event
    config = require("lapis.config").get!
    slug = "ludum-dare-#{config.comp_id}"
    {
      (assert Events\find(:slug), "failed to find default event by slug: #{slug}")
    }
  when "all" -- refresh every event
    Events\select!
  else -- reresh by slug
    {
      (assert Events\find(slug: event_slug), "invalid event: #{event_slug}")
    }

for event in *events
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




