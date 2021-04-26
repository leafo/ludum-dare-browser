import { h, render, Component } from "preact"

export default class NotFoundPage extends Component {
  render() {
    let message = this.props.message || "Ooops, this page wasn't found."

    return <div class="not_found_page">
      {message}
      {" "}
      <a href="/">Go home</a>
    </div>
  }
}
