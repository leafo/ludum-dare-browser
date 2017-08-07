import { h, render, Component } from "preact"
import classNames from "classnames"

import PillPicker from "ld/components/pill_picker"
import DropDownPicker from "ld/components/drop_down_picker"
import GameGrid from "ld/components/game_grid"

function encodeQueryString(obj) {
  let out = []
  for (let k in obj) {
    if (!obj.hasOwnProperty(k)) {
      continue
    }

    out.push(`${encodeURIComponent(k)}=${encodeURIComponent(obj[k])}`)
  }

  return out.join("&")
}

export default class Page extends Component {
  constructor(props) {
    super(props)
    this.state = {
      page: 0,
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
    xhr.open("GET", `/games/${this.props.event.slug}?${encodeQueryString(params)}`)

    xhr.addEventListener("readystatechange", e => {
      if (xhr.readyState != 4) return
      let res = JSON.parse(xhr.responseText)
      if (callback) {
        callback(res)
      }
    })

    xhr.send()
  }

  loadNextPage(done) {
    this.fetchGames(res => {
      this.setState({
        page: this.state.page + 1,
        games: this.state.games.concat(res.games || [])
      })
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
              {value: "unity", label: "Unity"},
              {value: "xna", label: "XNA"},
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

          <span class="icon icon-expand"></span>
          <PillPicker
            onChange={val => this.setState({cellSize: val}) }
            options={[
              {value: "small", label: "Small"},
              {value: "medium", label: "Medium", default: true},
              {value: "large", label: "Large"},
            ]} />

          <label title="Show Details">
            <input
              onChange={e => this.setState({showDetails: e.target.checked})}
              value={this.state.showDetails}
              type="checkbox" class="toggle_details" />
            <span class="icon-eye"></span>
          </label>
        </div>
      </div>

      <div class="itch_banner">
        <span class="icon-heart icon"></span>
        Into indie game development? Check out my other
        site, <a href="http://itch.io">itch.io</a>, host and sell your games with
        pay-what-you-want pricing. Thanks!
      </div>
      {
        this.state.games ? <GameGrid
          cellSize={this.state.cellSize}
          games={this.state.games}
          showDetails={this.state.showDetails}
          loadNextPage={this.loadNextPage.bind(this)}
        /> : null
      }
    </div>
  }
}
