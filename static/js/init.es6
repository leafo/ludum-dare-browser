
import Page from "ld/components/page"
import UserPage from "ld/components/user_page"
import AsyncEventPage from "ld/components/async_event_page"
import NotFoundPage from "ld/components/not_found_page"
import SearchPage from "ld/components/search_page"

import { render, h } from "preact"
import { Router } from "preactRouter"

import events from "ld/events"


function getQueryParam(name) {
  try {
    let params = new URLSearchParams(document.location.search.substring(1));
    return params.get(name)
  } catch(e) { }
}

export function init() {
  let defaultEvent = events.events.find(e => e.slug == events.default_event)

  let page = <Router>
    <Page path="/" key={defaultEvent.slug} event={defaultEvent} />
    <AsyncEventPage path="/jam/:eventSlug" />
    <UserPage path="/u/:userSlug" />
    <SearchPage path="/search" searchQuery={getQueryParam("q")} />
    <NotFoundPage default />
  </Router>

  render(page, document.body)
}
