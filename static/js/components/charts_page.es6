import { h, render, Component } from "preact"
import classNames from "classnames"
import {events} from "ld/events"

export default class ChartsPage extends Component {
  render() {
    return <div className="charts_page">
      <div id="toolbar" class="sticky">
        <h1>Ludum Dare Charts</h1>
      </div>

      <div className="page_column">
        <h2>Games Per Event</h2>
        {this.renderEventsGraph()}
      </div>

    </div>;
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

    return <div className="events_graph">
      {bars}
    </div>
  }
}

