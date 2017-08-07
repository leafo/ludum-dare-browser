import { h, render, Component } from "preact"
import classNames from "classnames"

export default class DropDownPicker extends Component {
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
    e.preventDefault()
    this.setState({
      open: !this.state.open
    })
  }

  setOption(opt) {
    this.setState({
      currentOption: opt.value,
      open: false,
    })

    if (this.props.onChange) {
      this.props.onChange(opt.value)
    }
  }

  renderOptions() {
    return <div class="select_popup">
      {this.props.options.map(opt => {
        if (opt == "divider") {
          return <hr />
        }

        return <button type="button" class={classNames("option", { selected: opt.value == this.state.currentOption})} onClick={e => this.setOption(opt)}>
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
        {" "}
        <span class="tri_down"></span>
      </button>
      {this.state.open ? this.renderOptions() : null}
    </div>
  }
}
