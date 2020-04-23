db = require "lapis.db"
url = require "socket.url"

import Flow from require "lapis.flow"

import Events, Games from require "models"

class FormatterFlow extends Flow
  event: (event) =>
    {
      id: event.id
      slug: event.slug
      name: event.name
      short_name: event\short_name!
      games_count: event.games_count
      last_refreshed_at: event.last_refreshed_at and event.last_refreshed_at\gsub "%.%d+$", ""
      url: @url_for event
      type: Events.types\to_name event.type
    }

  game: (game, thumb_size) =>
    event = game\get_event!

    fields = {
      "id", "downloads", "title", "votes_given", "votes_received", "is_jam",
      "user", "uid", "screenshots"
    }

    out = {f, game[f] for f in *fields}

    out.screenshot_url = game\screenshot_url @, thumb_size
    out.url = game\full_url!
    out.user_url = game\full_user_url!
    out.type = Events.types\to_name event.type

    out



