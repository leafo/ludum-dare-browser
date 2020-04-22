
import { h, render, Component, Fragment } from "preact"
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
    return <div class="game_browser">
      <div className="event_filters">
        {this.renderEventPicker()}

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

      <div class="itch_banner">
        <span class="icon-heart icon"></span>
        Into indie game development? Check <a href="https://itch.io">itch.io</a>, host and sell your games with
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

    let options = events.map(e => {
      let count = e.games_count || 0

      return {
        value: e.slug,
        href: e.url,
        default: e.slug == this.props.event.slug,
        label: <Fragment>
          {e.name}
          {" "}
          <span className="games_count">({count.toLocaleString()})</span>
        </Fragment>
      }
    })

    return <DropDownPicker options={options} alwaysInDom={true} />
  }
}
