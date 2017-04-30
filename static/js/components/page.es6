import { h, render, Component } from "preact"
import classNames from "classnames"

import PillPicker from "ld/components/pill_picker"
import DropDownPicker from "ld/components/drop_down_picker"

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

          <span class="icon icon-expand"></span>
          <PillPicker options={[
            {value: "small", label: "Small"},
            {value: "medium", label: "Medium"},
            {value: "large", label: "Large"},
          ]} />

          <label title="Show Details">
            <input type="checkbox" class="toggle_details" />
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
    </div>
  }
}
