import { h, render, Component } from "preact"
import classNames from "classnames"

class GameCell extends Component {
  componentDidMount() {
    let image = new Image()
    image.src = this.props.game.screenshot_url
    image.onload = () => this.setState({imageLoaded: true})
  }

  render() {
    let {
      url, user, user_url, title, uid, screenshot_url, votes_received,
      votes_given
    } = this.props.game

    return <div
      class={classNames("game_cell", { image_loading: !this.state.imageLoaded})}
      data-uid={ uid }
      style={{
        width: this.props.width ? `${this.props.width}px` : null,
        height: this.props.height ? `${this.props.height}px` : null,
      }}
    >
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
  componentDidMount() {
    this.setGridSizing(this.gameGridEl)

    this.resizeListener = () => this.setGridSizing(this.gameGridEl)
    this.scrollListener = () => {
      if (this.state.loading) {
        return
      }

      if (window.document.body.scrollTop + window.innerHeight > this.loaderEl.offsetTop) {
        this.setState({
          loading: true
        })

        if (this.props.loadNextPage) {
          this.props.loadNextPage(() => this.setState({ loading: false }))
        } else {
          console.warn("Missing props.loadNextPage")
        }
      }
    }

    window.addEventListener("resize", this.resizeListener)
    window.addEventListener("scroll", this.scrollListener)
  }

  componentDidUnmount() {
    window.removeEventListener("resize", this.resizeListener)
    window.removeEventListener("scroll", this.scrollListener)
  }

  render() {
    return <div class="game_grid" ref={ el => this.gameGridEl = el }>
      {this.props.games.map(game => {
        return this.renderGame(game)
      })}
      <div class="loader_cell" ref={ el => this.loaderEl = el}></div>
    </div>
  }

  setGridSizing(el) {
    let expectedWidth = 300
    let aspectRatio = 300/240

    let realWidth = expectedWidth + 20 // cell margin
    let pageWidth = el.clientWidth

    let numCells = pageWidth / realWidth
    let fract = numCells - Math.floor(numCells)

    let realNumCells

    if (fract < 0.5) {
      realNumCells = Math.floor(numCells)
    } else {
      realNumCells = Math.ceil(numCells)
    }

    let newWidth = (pageWidth / realNumCells) - 20 // remove cell margin
    let newHeight = newWidth / aspectRatio

    newWidth = Math.floor(newWidth)
    newHeight = Math.floor(newHeight)

    this.setState({
      gameCellWidth: newWidth,
      gameCellHeight: newHeight
    })

  }

  renderGame(game) {
    return <GameCell width={this.state.gameCellWidth} height={this.state.gameCellHeight} game={game} />
  }
}
