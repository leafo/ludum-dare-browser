
import Page from "ld/components/page"

import { render, h } from "preact"

export function init() {
  let props = {
    event_slug: "ludum-dare-39",
    event_name: "Ludum Dare 39",
    event_short_name: "LD39",
  }

  render(<Page {...props} />, document.body)
}
