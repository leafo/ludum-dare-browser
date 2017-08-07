import { h, render, Component } from "preact"

import Page from "ld/components/page"
import NotFoundPage from "ld/components/not_found_page"

export default class AsyncEventPage extends Component {
  componentDidMount() {
    this.loadEvent(res => {
      if (res.event) {
        this.setState({ event: res.event })
      } else {
        this.setState({ notFound: true })
      }
    })
  }

  loadEvent(callback) {
    let xhr = new XMLHttpRequest()
    xhr.open("GET", `/events/${this.props.eventSlug}`)

    xhr.addEventListener("readystatechange", e => {
      if (xhr.readyState != 4) return
      let res = JSON.parse(xhr.responseText)
      if (callback) {
        callback(res)
      }
    })

    xhr.send()
  }

  render() {
    if (this.state.event) {
      return <Page event={this.state.event} />
    }

    if (this.state.notFound) {
      return <NotFoundPage message="Oops, this jam doesn't exist" />
    }

    return <div class="loading_page">Loading</div>
  }
}

