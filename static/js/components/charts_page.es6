import { h, render, Component, Fragment } from "preact"
import classNames from "classnames"
import {events} from "ld/events"

let getEventBySlug = (slug) => events.find((e) => e.slug == slug)

class AsyncData extends Component {
  componentDidMount() {
    this.refresh()
  }

  refresh() {
    let xhr = new XMLHttpRequest()
    xhr.open("GET", this.props.url)

    xhr.addEventListener("readystatechange", e => {
      if (xhr.readyState != 4) return
      let res = JSON.parse(xhr.responseText)
      if (this.props.callback) {
        this.props.callback(res)
      }
      this.setState({
        data: res
      })
    })

    xhr.send()
  }

  render() {
    if (this.state.data) {
      return this.props.renderData(this.state.data)
    } else {
      return this.props.children
    }
  }
}


export default class ChartsPage extends Component {
  render() {
    let totalSubmissions = events.reduce((v, e) => v + (e.games_count || 0), 0)
    let totalRatings = null
    if (this.state.data) {
      totalRatings = this.state.data.event_votes.reduce((v, e) => v + (e.total_votes || 0), 0)
    }

    return <div className="charts_page">
      <div class="event_filters">
        <h2>Charts</h2>
        {" "}
        <a href="/">Return home</a>
      </div>

      <div className="page_column">
        <p>Note: All data limited to the events that were able to be scraped, from Ludum Dare 15 onwards.</p>

        <div class="aggregate_stats">
          <div class="stat_box">
            <span class="value">{totalSubmissions.toLocaleString()}</span>
            <span class="label">Total Games</span>
          </div>

          <div class="stat_box">
            <span class="value">{totalRatings != null ? totalRatings.toLocaleString() : "…"}</span>
            <span class="label">Total Ratings</span>
          </div>
        </div>

        {this.renderEventsGraph()}

        <AsyncData url="/stats/events" renderData={this.renderAsyncStats.bind(this)} callback={d => this.setState({data: d})}>
          <div>Loading...</div>
        </AsyncData>

        <p>Ideas for more charts or graphs? <a href="https://github.com/leafo/ludum-dare-browser/issues">Open a request on GitHub</a>.</p>
      </div>
    </div>
  }

  renderAsyncStats(data) {
    return <Fragment>
      {this.renderVotesGraph(data.event_votes)}
      {this.renderTopSubmitters(data.top_users_submissions)}
      {this.renderTopVotesGiven(data.top_users_votes_given)}
      {this.renderTopVotesReceived(data.top_users_votes_received)}
    </Fragment>
  }

  renderTopSubmitters(users) {
    if (!users) {
      return null
    }

    return <Fragment>
      <h2>Most Submissions by Username</h2>
      <p>Note: This will not handle when a username was changed for Ludum Dare site migration</p>
      <table cellSpacing="0" cellPadding="0">
        <thead>
          <tr>
            <td>Account</td>
            <td>Submissions</td>
            <td>First seen</td>
            <td>Last seen</td>
            <td>Ratings given</td>
            <td>Ratings received</td>
          </tr>
        </thead>

        <tbody>
          {users.map(user => {
            let firstEvent = getEventBySlug(user.first_seen)
            let lastEvent = getEventBySlug(user.last_seen)

            return <tr>
              <td>
                <a href={`/u/${encodeURIComponent(user.user)}`}>{user.user}</a>
              </td>
              <td>{(user.submissions_count || 0).toLocaleString()}</td>
              <td>
                {firstEvent ? <a href={firstEvent.url}>{firstEvent.name}</a> : null}
              </td>
              <td>
                {lastEvent ? <a href={lastEvent.url}>{lastEvent.name}</a> : null}
              </td>
              <td>{(user.votes_given || 0).toLocaleString()}</td>
              <td>{(user.votes_received || 0).toLocaleString()}</td>
            </tr>
          })}
        </tbody>
      </table>
    </Fragment>
  }
  renderTopVotesGiven(users) {
    if (!users) {
      return null
    }

    return <Fragment>
      <h2>Top Users By Ratings Given</h2>
      <table>
        <thead>
          <tr>
            <td>User</td>
            <td>Ratings Given</td>
            <td>Ratings Received</td>
          </tr>
        </thead>
        <tbody>
          {users.map((user) => {
            return <tr>
              <td>
                <a href={`/u/${encodeURIComponent(user.user)}`}>{user.user}</a>
              </td>
              <td>{(user.votes_given || 0).toLocaleString()}</td>
              <td>{(user.votes_received || 0).toLocaleString()}</td>
            </tr>
          })}
        </tbody>
      </table>
    </Fragment>
  }

  renderTopVotesReceived(users) {
    if (!users) {
      return null
    }

    return <Fragment>
      <h2>Top Users By Ratings Received</h2>
      <table>
        <thead>
          <tr>
            <td>User</td>
            <td>Ratings Given</td>
            <td>Ratings Received</td>
          </tr>
        </thead>
        <tbody>
          {users.map((user) => {
            return <tr>
              <td>
                <a href={`/u/${encodeURIComponent(user.user)}`}>{user.user}</a>
              </td>
              <td>{(user.votes_given || 0).toLocaleString()}</td>
              <td>{(user.votes_received || 0).toLocaleString()}</td>
            </tr>
          })}
        </tbody>
      </table>
    </Fragment>
  }

  renderVotesGraph(votes) {
    return <Fragment>
      <h2>Ratings Per Event</h2>
      {this._renderBarGraph(votes, "total_votes")}
    </Fragment>
  }

  renderEventsGraph() {
    const max = Math.max(...events.map(e => e.games_count || 0))

    let bars = events.map((e, idx) => 
      <div className="event_column" key={idx}>
        <div className="event_name">
          <a href={e.url}>{e.short_name}</a>
        </div>
        <div className="event_bar">
          <div className="bar_inner" style={{
            height: `${(e.games_count || 0) / max * 100}%`
          }}>
            <span>{(e.games_count || 0).toLocaleString()}</span>
          </div>
        </div>
      </div>
    )

    return <Fragment>
      <h2>Games Per Event</h2>
      {this._renderBarGraph(events, "games_count")}
    </Fragment>
  }

  _renderBarGraph(items, field) {
    const max = Math.max(...items.map(e => e[field] || 0))

    let bars = items.map((e, idx) => 
      <div className="event_column" key={idx}>
        <div className="event_name">
          <a href={e.url}>{e.short_name || e.name}</a>
        </div>
        <div className="event_bar">
          <div className="bar_inner" style={{
            height: `${(e[field] || 0) / max * 100}%`
          }}>
            <span>{(e[field] || 0).toLocaleString()}</span>
          </div>
        </div>
      </div>
    )

    return <div class="events_graph">{bars}</div>
  }




}

