import { h, render, Component } from "preact"
import classNames from "classnames"

class GameCell extends Component {
  componentDidMount() {
    console.log("added game")
  }

  componentDidUnmount() {
    console.log("removed game")
  }

  render() {
    let {
      url, user, user_url, title, uid, screenshot_url, votes_received,
      votes_given
    } = this.props.game

    return <div class="game_cell image_loading" data-uid={ uid }>
      <a href={url} target="_blank" class="thumb" style={{
        backgroundImage: `url('${screenshot_url}')`
      }}></a>
      <div class="top_label">
        <div class="votes">
          <span title="Votes Received">
            <span class="icon icon-star"></span> { votes_received }
          </span>
          <span class="divider"> </span>
          <span title="Coolness">
            <span class="icon icon-cool"></span> { votes_given }
          </span>
        </div>

        <div class="downloads">
          <span class="icon icon-box-add" title="Show Downloads"></span>
        </div>
      </div>


      <div class="label">
        <div class="text">
          <a href={user_url} target="_blank" class="author">{user}</a>
          <a href={url} target="_blank" title={title} class="title">{title}</a>
        </div>
      </div>
    </div>
  }

}

export default class GameGrid extends Component {
  render() {
    return <div class="game_grid">
      {this.props.games.map(game => {
        return this.renderGame(game)
      })}
    </div>
  }

  renderGame(game) {
    return <GameCell game={game} />
  }
}
