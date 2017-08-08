import { h, render, Component } from "preact"
import classNames from "classnames"

import BaseGridPage from "ld/components/base_grid_page"
import PillPicker from "ld/components/pill_picker"
import DropDownPicker from "ld/components/drop_down_picker"
import GameGrid from "ld/components/game_grid"

import {events} from "ld/events"


export default class Page extends BaseGridPage {
  constructor(props) {
    super(props)
    this.state = {
      page: 0,
      hasMore: true,
      showDetails: false,
      cellSize: "medium",
      randomSeed: Math.floor(Math.random() * 100000),
      games: [],
      filter: {},
    }
  }

  componentDidMount() {
    this.loadNextPage()
  }

  fetchGames(callback) {
    this.setState({loading: true })

    let params = {page: this.state.page, ...this.state.filter}
    if (params.sort == "random") {
      params.seed = this.state.randomSeed
    }

    let xhr = new XMLHttpRequest()
    xhr.open("GET", `/games/${this.props.event.slug}?${this.encodeQueryString(params)}`)

    xhr.addEventListener("readystatechange", e => {
      if (xhr.readyState != 4) return
      this.setState({loading: false })

      let res = JSON.parse(xhr.responseText)
      if (callback) {
        callback(res)
      }
    })

    xhr.send()
  }

  loadNextPage(done) {
    this.fetchGames(res => {
      if (!res.games) {
        this.setState({
          hasMore: false
        })
      } else {
        this.setState({
          page: this.state.page + 1,
          games: this.state.games.concat(res.games || [])
        })
      }

      if (done) {
        done()
      }
    })
  }

  updateFilter(update) {
    this.setState({
      page: 0,
      games: [],
      filter: {...this.state.filter, ...update},
    }, () => this.loadNextPage())
  }

  render() {
    let shareTitle = `${this.props.event.name} Game Browser`

    let socialButtons = <div class="social_buttons">
      <a href="https://twitter.com/moonscript" class="twitter-follow-button" data-show-screen-name="false" data-show-count="false">Follow @moonscript</a>
      {" "}

      <a href="https://twitter.com/share" class="twitter-share-button" data-url="http://ludumdare.itch.io" data-text={shareTitle} data-via="moonscript" data-related="moonscript">Tweet</a>
    </div>

    socialButtons = null // hide for now

    return <div class="game_browser">
      <div id="toolbar" class="sticky">
        <h1 class="long_header">{this.props.event.name} Games</h1>
        <h1 class="short_header">{this.props.event.short_name}</h1>

        {socialButtons}

        <div class="spacer"></div>

        <div class="tools">
          <span class="icon icon-paragraph-justify"></span>
          <DropDownPicker
            onChange={val => this.updateFilter({collection: val})}
            options={[
              {value: "all", label: "All Games"},
              "divider",
              {value: "windows", label: "Windows"},
              {value: "osx", label: "OSX"},
              {value: "linux", label: "Linux"},
              {value: "android", label: "Android"},
              "divider",
              {value: "flash", label: "Flash"},
              {value: "html5", label: "HTML5"},
              {value: "java", label: "Java"},
              {value: "love", label: "LÖVE"},
              {value: "itchio", label: "itch.io"},
            ]}/>

          <DropDownPicker
            onChange={val => this.updateFilter({sort: val})}
            options={[
              {value: "random", label: "Random"},
              {value: "votes", label: "Most rated", default: true},
              {value: "votes_reverse", label: "Least rated"},
              {value: "coolness", label: "Most ratings given"},
              {value: "coolness_reverse", label: "Least ratings given"},
            ]}/>

          {this.renderSizePicker()}
          {this.renderDetailsToggle()}
        </div>
      </div>

      {this.renderEventPicker()}

      <div class="itch_banner">
        <span class="icon-heart icon"></span>
        Into indie game development? Check out my other
        site, <a href="http://itch.io">itch.io</a>, host and sell your games with
        pay-what-you-want pricing. Thanks!
      </div>
      {
        this.state.games ? <GameGrid
          hasMore={this.state.hasMore}
          cellSize={this.state.cellSize}
          ref={grid => this.currentGrid = grid}
          games={this.state.games}
          showDetails={this.state.showDetails}
          loadNextPage={this.loadNextPage.bind(this)}
        /> : null
      }
    </div>
  }

  renderEventPicker() {
    if (!events || !events.length) {
      return
    }

    let displayEvents = events.filter(e => e.slug != this.props.event.slug)

    let eventElements = displayEvents.map(e => {
      return <li class="event">
        <a href={e.url}>{e.short_name || e.name}</a>
        {" "}
        <span class="games_count">({e.games_count})</span>
      </li>
    })

    return <div class="jam_picker">
      <strong>Previous jams:</strong>
      <ul>{eventElements}</ul>
    </div>
  }
}
