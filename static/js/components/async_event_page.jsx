import { h, render, Component } from "preact"

import Page from "./page"
import NotFoundPage from "./not_found_page"

export default class AsyncEventPage extends Component {
  componentDidMount() {
    this.loadEvent()
  }

  componentDidUpdate(prevProps) {
    if (prevProps.eventSlug != this.props.eventSlug) {
      this.loadEvent()
    }
  }

  loadEvent() {
    this.setState({
      event: null,
      notFound: false
    })

    this.getEvent(res => {
      if (res.event) {
        this.setState({ event: res.event })
      } else {
        this.setState({ notFound: true })
      }
    })
  }

  getEvent(callback) {
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
      return <Page key={this.state.event.slug} event={this.state.event} />
    }

    if (this.state.notFound) {
      return <NotFoundPage message="Oops, this jam doesn't exist" />
    }

    return <div class="loading_page">Loading</div>
  }
}

