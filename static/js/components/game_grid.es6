import { h, render, Component } from "preact"
import classNames from "classnames"

import {bindMenusBodyClick, pushOpenMenu, removeClosedMenu} from 'ld/menus'

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
    bindMenusBodyClick()
    if (this.supportsLazyImages()) {
      let handleIntersect = (entities) => {
        for (let entity of entities) {
          if (entity.isIntersecting) {
            this.displayImage()
          }
        }
      }
      this.observer = new IntersectionObserver(handleIntersect, {})
      this.observer.observe(this.base)
    } else {
      this.displayImage()
    }
  }

  displayImage() {
    if (this.state.displayImage) {
      return
    }

    if (this.observer) {
      this.observer.unobserve(this.base)
    }

    this.setState({
      displayImage: true
    })

    let image = new Image()
    image.src = this.props.game.screenshot_url
    image.onload = () => this.setState({imageLoaded: true})
  }

  supportsLazyImages() {
    return "IntersectionObserver" in window
  }

  componentWillUnmount() {
    removeClosedMenu(this)
    if (this.observer) {
      this.observer.disconnect()
    }
  }

  shouldComponentUpdate(nextProps, nextState) {
    return isDifferent(this.props, nextProps) || isDifferent(this.state, nextState)
  }

  close() { // for the menu manager callback
    if (this.state.downloadMenuOpen) {
      this.toggleDownloadMenu()
    }
  }

  toggleDownloadMenu() {
    this.setState({
      downloadMenuOpen: !this.state.downloadMenuOpen
    }, () => {
      if (this.state.downloadMenuOpen) {
        pushOpenMenu(this)
      } else {
        removeClosedMenu(this)
      }
    })
  }

  // for formatting domain on downloads menhu
  parseDomain(url) {
    let el = document.createElement("a")
    el.href = url
    return el.hostname
  }

  render() {
    let {
      url, user, user_url, title, id, screenshot_url, votes_received,
      votes_given
    } = this.props.game

    let downloadsMenu

    if (this.state.downloadMenuOpen) {
      downloadsMenu = <ul class="downloader arrow_box visible toggle_dropdown">
        {this.props.game.downloads.map(download => {
          let hostname = this.parseDomain(download.href)

          return <li>
            <a href={download.href} target="_blank">{download.label}</a>
            {" "}
            {hostname ? <span class="hostname">({hostname})</span> : null}
          </li>
        })}
      </ul>
    }

    let downloadsButton

    if (this.props.game.downloads) {
      downloadsButton = <div class="downloads">
        <button
          onClick={e => this.toggleDownloadMenu() }
          class="icon icon-box-add toggle_dropdown" title="Show Downloads"></button>
      </div>
    }

    let coolnessLabel = "Coolness"
    if (this.props.game.type == "ldjam") {
      coolnessLabel = "Votes given"
    }

    let thumbStyle = {}

    if (this.state.displayImage) {
      thumbStyle = {
        backgroundImage: `url('${screenshot_url}')`
      }
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
      <div class="cell_crop">
        <a href={url} target="_blank" class="thumb" style={thumbStyle}></a>
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

          {downloadsButton}
        </div>

        <div class="label">
          <div class="text">
            <a href={`/u/${user}`} class="author">{user}</a>
            <a href={url} target="_blank" title={title} class="title">{title}</a>
          </div>
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

      if (!this.loaderEl) {
        return
      }

      let scroll = document.documentElement.scrollTop || document.body.scrollTop || 0

      if (scroll + window.innerHeight > this.loaderEl.offsetTop) {
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

  componentWillUnmount() {
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

    let loader

    if (this.props.hasMore) {
      loader = <div class="loader_cell" style={size} ref={ el => this.loaderEl = el}></div>
    }

    return <div
      class={classNames("game_grid details_enabled", {show_labels: this.props.showDetails})}
      ref={ el => this.gameGridEl = el }
    >
      {this.props.games.map(game => {
        return this.renderGame(game)
      })}
      {loader}
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
