import { h, render, Component } from "preact"
import classNames from "classnames"
import {events} from "ld/events"

import BaseGridPage from "ld/components/base_grid_page"
import GameGrid from "ld/components/game_grid"

export default class UserPage extends BaseGridPage {
  constructor(props) {
    super(props)
    this.state = {
      page: 0,
      showDetails: false,
      cellSize: "medium",
      games: [],
    }
  }

  componentDidMount() {
    this.loadGames()
  }

  render() {
    let links = this.getProfileLinks()

    let emptyMessage
    if (this.state.games && !this.state.games.length) {
      emptyMessage = <p class="empty_message">Nothing found :(</p>
    }

    return <div class="game_browser user_page">
      <div id="toolbar" class="sticky">
        <h1>Ludum Dare Submissions by {this.props.userSlug}</h1>
        <div class="spacer"></div>
        <div class="tools">
          {this.renderSizePicker()}
          {this.renderDetailsToggle()}
        </div>
      </div>

      <div class="jam_picker">
        <a href="/">Return home</a>
        <div class="spacer"></div>
        <strong>Profile links: </strong>
        <ul>
          {links.map(obj => {
            return <li>
              <a href={obj.href} target="_blank">{obj.label}</a>
            </li>
          })}
          {links.length ? null : "None"}
        </ul>
      </div>

      {
        this.state.games ? <GameGrid
          hasMore={false}
          cellSize={this.state.cellSize}
          ref={grid => this.currentGrid = grid}
          games={this.state.games}
          showDetails={this.state.showDetails}
        /> : null
      }
      {emptyMessage}
    </div>
  }

  getProfileLinks() {
    if (!this.state.games) {
      return []
    }

    let seen = {}
    let urls = []

    let ahref = document.createElement("a")

    for (let game of this.state.games) {
      if (seen[game.user_url]) {
        continue
      }
      seen[game.user_url] = true
      ahref.href = game.user_url

      urls.push({
        label: ahref.hostname,
        href: game.user_url
      })
    }

    return urls
  }

  loadGames() {
    this.fetchGames(res => {
      this.setState({
        games: res.games || []
      })
    })
  }

  fetchGames(callback) {
    this.setState({loading: true })

    let xhr = new XMLHttpRequest()
    xhr.open("GET", `/users/${this.props.userSlug}/games`)

    xhr.addEventListener("readystatechange", e => {
      if (xhr.readyState != 4) return
      this.setState({ loading: false })

      let res = JSON.parse(xhr.responseText)
      if (callback) {
        callback(res)
      }
    })

    xhr.send()
  }
}

