import { h, render, Component } from "preact"
import classNames from "classnames"
import {events} from "ld/events"

import BaseGridPage from "ld/components/base_grid_page"
import GameGrid from "ld/components/game_grid"

export default class SearchPage extends BaseGridPage {
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
    let emptyMessage
    if (this.state.games && !this.state.games.length) {
      emptyMessage = <p class="empty_message">Nothing found :(</p>
    }

    return <div class="game_browser search_page">
      <div class="event_filters">
        <h2 class="current_query">Searching for '{this.props.searchQuery}'</h2>
        {"  "}
        <a href="/">Return home</a>
        {"  "}
        {this.renderDisplayOptions()}
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

    xhr.open("GET", `/search/games?${this.encodeQueryString({
      q: this.props.searchQuery
    })}`)

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

