
import Page from "ld/components/page"
import NotFoundPage from "ld/components/not_found_page"

import { render, h } from "preact"
import { Router } from "preactRouter"

export function init() {
  let props = {
    event_slug: "ludum-dare-39",
    event_name: "Ludum Dare 39",
    event_short_name: "LD39",
  }

  let page = <Router>
    <Page path="/" {...props} />
    <NotFoundPage default />
  </Router>

  render(page, document.body)
}
