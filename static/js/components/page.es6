import { h, render, Component } from "preact"
import classNames from "classnames"

class DropDownPicker extends Component {
  constructor(props) {
    super(props)
    let current = this.props.options.find(e => e.default) || this.props.options.find(e => e.value)

    this.state = {
      currentOption: current.value,
      open: false,
    }
  }

  getCurrentOption() {
    return this.props.options.find(e => e.value == this.state.currentOption)
  }

  onClick(e) {
    this.setState({
      open: !this.state.open
    })
  }

  setOption(opt) {
    this.setState({
      currentOption: opt.value,
      open: false,
    })
  }

  renderOptions() {
    return <div class="select_popup">
      {this.props.options.map(opt => {
        if (opt == "divider") {
          return <hr />
        }

        return <button class={classNames("option", { selected: opt.value == this.state.currentOption})} onClick={e => this.setOption(opt)}>
          {opt.label}
        </button>
      })}
    </div>
  }

  render() {
    let current = this.getCurrentOption()

    return <div class={classNames("dropdown_picker", {open: this.state.open})}>
      <button class="current_option" onClick={e => this.onClick(e)}>
        <span class="label">{current.label}</span>
        <span class="tri_down"></span>
      </button>
      {this.state.open ? this.renderOptions() : null}
    </div>
  }
}

export default class Page extends Component {
  render() {
    return <div class="game_browser">
      <div id="toolbar" class="sticky">
        <h1 class="long_header">Ludum Dare 37 Games</h1>
        <h1 class="short_header">LD37</h1>

        <div class="social_buttons">
          <a href="https://twitter.com/moonscript" class="twitter-follow-button" data-show-screen-name="false" data-show-count="false">Follow @moonscript</a>
          {" "}

          <a href="https://twitter.com/share" class="twitter-share-button" data-url="http://ludumdare.itch.io" data-text="Ludum Dare 37 Game Browser" data-via="moonscript" data-related="moonscript">Tweet</a>
        </div>


        <div class="spacer"></div>

        <div class="tools">
          <span class="icon icon-paragraph-justify"></span>
          <DropDownPicker options={[
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

          <DropDownPicker options={[
            {value: "random", label: "Random"},
            {value: "votes", label: "Most Rated", default: true},
            {value: "votes_reverse", label: "Least rated"},
            {value: "coolness", label: "Most Coolness"},
            {value: "coolness_reverse", label: "Least Coolness"},
          ]}/>
        </div>
      </div>

      <div class="itch_banner">
        <span class="icon-heart icon"></span>
        Into indie game development? Check out my other
        site, <a href="http://itch.io">itch.io</a>, host and sell your games with
        pay-what-you-want pricing. Thanks!
      </div>
    </div>
  }
}
