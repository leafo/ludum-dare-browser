
import Page from "ld/components/page"
import UserPage from "ld/components/user_page"
import AsyncEventPage from "ld/components/async_event_page"
import NotFoundPage from "ld/components/not_found_page"

import { render, h } from "preact"
import { Router } from "preactRouter"

import events from "ld/events"

export function init() {
  let defaultEvent = events.events.find(e => e.slug == events.default_event)

  let page = <Router>
    <Page path="/" key={defaultEvent.slug} event={defaultEvent} />
    <AsyncEventPage path="/jam/:eventSlug" />
    <UserPage path="/u/:userSlug" />
    <NotFoundPage default />
  </Router>

  render(page, document.body)
}
