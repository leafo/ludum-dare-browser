import { h, render, Component } from "preact"
import classNames from "classnames"

function isDifferent(a, b) {
  for (let key in a) {
    if (a[key]!==b[key]) {
      return true
    }
  }

  for (let key in b) {
    if (!(key in a)) {
      return true
    }
  }

  return false;
}

class GameCell extends Component {
  componentDidMount() {
    let image = new Image()
    image.src = this.props.game.screenshot_url
    image.onload = () => this.setState({imageLoaded: true})
  }

  shouldComponentUpdate(nextProps, nextState) {
    return isDifferent(this.props, nextProps) || isDifferent(this.state, nextState)
  }

  toggleDownloadMenu() {
    this.setState({
      downloadMenuOpen: !this.state.downloadMenuOpen
    })
  }

  render() {
    let {
      url, user, user_url, title, id, screenshot_url, votes_received,
      votes_given
    } = this.props.game

    let downloadsMenu

    if (this.state.downloadMenuOpen) {
      downloadsMenu = <ul class="downloader arrow_box visible">
        {this.props.game.downloads.map(download => {
          return <li>
            <a href={download.href} target="_blank">{download.label}</a>
          </li>
        })}
      </ul>
    }

    let coolnessLabel = "Coolness"
    if (this.props.game.type == "ldjam") {
      coolnessLabel = "Votes given"
    }

    return <div
      class={classNames("game_cell", {
        image_loading: !this.state.imageLoaded,
        show_details: this.state.downloadMenuOpen
      })}
      data-id={ id }
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
          <span title={coolnessLabel}>
            <span class="icon icon-cool"></span> { votes_given }
          </span>
        </div>

        <div class="downloads">
          <button
            onClick={e => this.toggleDownloadMenu() }
            class="icon icon-box-add" title="Show Downloads"></button>
        </div>
      </div>

      <div class="label">
        <div class="text">
          <a href={user_url} target="_blank" class="author">{user}</a>
          <a href={url} target="_blank" title={title} class="title">{title}</a>
        </div>
      </div>

      {downloadsMenu}
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

  componentDidUpdate(prevProps) {
    if (this.props.cellSize != prevProps.cellSize) {
      this.setGridSizing(this.gameGridEl)
    }
  }

  render() {
    let size = {
      width: `${this.state.gameCellWidth}px`,
      height: `${this.state.gameCellHeight}px`,
    }

    return <div
      class={classNames("game_grid details_enabled", {show_labels: this.props.showDetails})}
      ref={ el => this.gameGridEl = el }
    >
      {this.props.games.map(game => {
        return this.renderGame(game)
      })}
      <div class="loader_cell" style={size} ref={ el => this.loaderEl = el}></div>
    </div>
  }

  setGridSizing(el) {
    let expectedWidth = ({
      small: 180,
      medium: 300,
      large: 500,
    })[this.props.cellSize || "medium"]

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
