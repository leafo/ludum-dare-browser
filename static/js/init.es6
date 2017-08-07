
import Page from "ld/components/page"
import AsyncEventPage from "ld/components/async_event_page"
import NotFoundPage from "ld/components/not_found_page"

import { render, h } from "preact"
import { Router } from "preactRouter"

export function init() {
  let defaultEvent = {
    slug: "ludum-dare-39",
    name: "Ludum Dare 39",
    short_name: "LD39",
  }

  let page = <Router>
    <Page path="/" event={defaultEvent} />
    <AsyncEventPage path="/jam/:eventSlug" />
    <NotFoundPage default />
  </Router>

  render(page, document.body)
}
