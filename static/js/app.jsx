import Page from "./components/page"
import UserPage from "./components/user_page"
import AsyncEventPage from "./components/async_event_page"
import NotFoundPage from "./components/not_found_page"
import SearchPage from "./components/search_page"
import ChartsPage from "./components/charts_page"

import { render, h } from "preact"
import { Router } from "preact-router"

import events from "ld/events"

function getQueryParam(name) {
  try {
    let params = new URLSearchParams(document.location.search.substring(1));
    return params.get(name)
  } catch(e) { }
}

let defaultEvent = events.events.find(e => e.slug == events.default_event)

let page = <div class="layout">
  <header id="header">
    <h1>
      <a href="/">Ludum Dare Games</a>
    </h1>

    <form action="/search" class="search_form">
      <input
        placeholder="Search games or creators..."
        type="text" name="q" defaultValue={getQueryParam("q")} />
    </form>

    <Router>
      <a path="/charts" class="nav_link active" href="/charts">Charts</a>
      <a default class="nav_link" href="/charts">Charts</a>
    </Router>
    {" "}
    <a class="nav_link" href="https://github.com/leafo/ludum-dare-browser">GitHub</a>
  </header>

  <main class="page_content">
    <Router>
      <Page path="/" key={defaultEvent.slug} event={defaultEvent} />
      <AsyncEventPage path="/jam/:eventSlug" />
      <UserPage path="/u/:userSlug" />
      <SearchPage path="/search" searchQuery={getQueryParam("q")} />
      <ChartsPage path="/charts" />
      <NotFoundPage default />
    </Router>
  </main>
</div>

render(page, document.body)
