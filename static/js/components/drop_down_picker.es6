import { h, render, Component } from "preact"
import classNames from "classnames"

import {bindMenusBodyClick, pushOpenMenu, removeClosedMenu} from 'ld/menus'

export default class DropDownPicker extends Component {
  constructor(props) {
    super(props)
    let current = this.props.options.find(e => e.default) || this.props.options.find(e => e.value)

    this.state = {
      currentOption: current.value,
      open: false,
    }
  }

  componentDidMount() {
    bindMenusBodyClick()
  }

  componentWillUnmount() {
    removeClosedMenu(this)
  }

  getCurrentOption() {
    return this.props.options.find(e => e.value == this.state.currentOption)
  }

  close() {
    this.setState({
      open: false
    }, () => {
      if (!this.state.open) {
        removeClosedMenu(this)
      }
    })
  }

  open() {
    this.setState({
      open: true
    }, () => {
      if (this.state.open) {
        pushOpenMenu(this)
      }
    })
  }

  onClick(e) {
    e.preventDefault()
    if (this.state.open) {
      this.close()
    } else {
      this.open()
    }
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

        let inside = opt.label
        let classes = classNames("option", { selected: opt.value == this.state.currentOption})


        if (opt.href) {
          return <a href={opt.href} class={classes} onClick={e => this.setOption(opt)}>
            {inside}
          </a>
        } else {
          return <button type="button" class={classes} onClick={e => this.setOption(opt)}>
            {inside}
          </button>
        }
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
