import { h, render, Component } from "preact"

export default class NotFoundPage extends Component {
  render() {
    return <div class="not_found_page">
      Ooops, this page wasn't found.
      {" "}
      <a href="/">Go home</a>
    </div>
  }
}
