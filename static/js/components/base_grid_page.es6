
import { h, render, Component } from "preact"
import classNames from "classnames"

import PillPicker from "ld/components/pill_picker"
import DropDownPicker from "ld/components/drop_down_picker"

export default class BaseGridPage extends Component {
  encodeQueryString(obj) {
    let out = []
    for (let k in obj) {
      if (!obj.hasOwnProperty(k)) {
        continue
      }

      out.push(`${encodeURIComponent(k)}=${encodeURIComponent(obj[k])}`)
    }

    return out.join("&")
  }

  renderDetailsToggle() {
    return <label title="Show Details" class="details_toggle">
      <input
        onChange={e => this.setState({showDetails: e.target.checked})}
        value={this.state.showDetails}
        type="checkbox" class="toggle_details" />
      <span class="icon-eye"></span>
    </label>

  }
  renderSizePicker() {
    return <span clas="size_picker">
    <span class="icon icon-expand"></span>
    <PillPicker
      onChange={val => {
        this.setState({
          cellSize: val
        }, () => {
          if (this.currentGrid) {
            this.currentGrid.scrollListener()
          }
        })
      }}
      options={[
        {value: "small", label: "Small"},
        {value: "medium", label: "Medium", default: true},
        {value: "large", label: "Large"},
      ]} />
    </span>
  }

}

