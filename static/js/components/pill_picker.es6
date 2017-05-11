import { h, render, Component } from "preact"
import classNames from "classnames"

export default class PillPicker extends Component {
  constructor(props) {
    super(props)
    let current = this.props.options.find(e => e.default) || this.props.options[0]
    this.state = {
      currentOption: current.value,
    }
  }

  setOption(opt) {
    this.setState({
      currentOption: opt.value
    })

    if (this.props.onChange) {
      this.props.onChange(opt.value)
    }
  }

  renderOptions() {
    return this.props.options.map(opt => {
      return <button type="button" class={classNames("picker", {current: opt.value == this.state.currentOption})} onClick={e => this.setOption(opt)}>
        {opt.label}
      </button>
    })
  }

  render() {
    return <div class="size_picker">
      {this.renderOptions()}
    </div>
  }
}
