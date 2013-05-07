window.I ||= {}

_.templateSettings = {
  interpolate : /\{\{(.+?)\}\}/g
}

class I.GamePage
  setup_sort_picker: ->
    @sort_picker = $ "#sort_picker"
    sort_popup = @sort_picker.find ".select_popup"
    t = null

    close_sort_picker = =>
      clearTimeout t if t
      @sort_picker.removeClass "open"
      t = setTimeout =>
        sort_popup.css { left: "", right: ""}
        t = null
      , 200

    set_value = (label) =>
      @sort_picker.find(".current_option .label").html label

    @sort_picker.on "click", ".current_option", (e) =>
      if @sort_picker.is ".open"
        close_sort_picker()
      else
        clearTimeout t if t
        t = null

        elm = $(e.currentTarget)
        pos = elm.position()
        @sort_picker.addClass "open"
        sort_popup.css {
          left: "#{Math.floor pos.left + elm.outerWidth() - sort_popup.width() / 2}px"
          top: "#{pos.top + elm.height()}px"
        }

    @sort_picker.on "click", ".option", (e) =>
      option = $(e.currentTarget)
      mode = option.data "sort"
      set_value option.text()
      close_sort_picker()
      @list.sort = mode
      @list.reset()

    $(window.document).on "click", (e) =>
      if @sort_picker.is ".open"
        unless $(e.target).closest(".sort_picker").length
          close_sort_picker()

    $(window).on "resize", =>
      close_sort_picker() if @sort_picker.is ".open"

  setup_size_picker: =>
    @size_picker = $ "#size_picker"
    pickers = @size_picker.find ".picker"
    @size_picker.on "click", ".picker", (e) =>
      pickers.removeClass "current"
      p = $(e.currentTarget).addClass "current"
      @list.set_size p.data "size"

  constructor: ->
    window.thelist = @list = new I.GameList $ "#game_list"
    @toolbar = $("#toolbar")

    @toolbar.on "change", "input.toggle_details", (e) =>
      checked = $(e.currentTarget).prop "checked"
      @list.el.toggleClass "show_labels", checked

    @setup_size_picker()
    @setup_sort_picker()

class I.GameList
  current_page: 0
  aspect_ratio: 300/240
  cell_size: "medium"
  sort: "votes"

  cell_sizes: {
    small: 180 # 220
    medium: 300 # 340
    large: 500 # 360
  }

  set_size: (size) ->
    size = "medium" if !@cell_sizes[size]
    @cell_size = size
    @reset()
    @resize_cells @cell_sizes[size]

  reset: =>
    @current_page = 0
    @el.empty().append @_loader
    @fetch_page()

  resize_cells: (expected_width) =>
    real_width = expected_width + 20 # cell margin
    page_width = @el.width()

    num_cells = page_width / real_width
    fract = num_cells - Math.floor(num_cells)
    if fract < 0.5
      real_num_cells = Math.floor(num_cells)
    else
      real_num_cells = Math.ceil(num_cells)

    new_width = (page_width / real_num_cells) - 20 # remove cell margin
    new_height = new_width / @aspect_ratio

    new_width = Math.floor new_width
    new_height = Math.floor new_height

    @_style.remove() if @_style
    css = """
      .game_cell, .loader_cell {
        width: #{new_width}px;
        height: #{new_height}px;
      }
    """

    @_style = $("<style type='text/css'>#{css}</style>").appendTo $("head")

  render_game: (game) =>
    @downloads[game.uid] = game.downloads
    @_tpl ||= _.template $("#game_template").html()
    game_el = $($.trim @_tpl game).appendTo @el
    $("<img />").attr("src", game.screenshot_url).on "load", =>
      game_el.removeClass "image_loading"

  hide_downloads: ->
    @_tooltip ||= $("#download_tooltip")
    @_open_cell?.removeClass "show_details"
    @_open_cell = null
    @_tooltip.removeClass("animated visible").css {
      top: ""
      left: ""
    }

  # takes download element
  show_downloads: (elm) ->
    @_tooltip ||= $("#download_tooltip")
    cell = elm.closest(".game_cell")
    pos = elm.offset()


    if @_open_cell?.is cell
      @hide_downloads()
      return

    if @_open_cell
      @_open_cell.removeClass "show_details"

    @_open_cell = cell.addClass "show_details"

    @_tooltip.empty()
    if downloads = @downloads[cell.data "uid"]
      for dl in downloads
        $('<a class="download_row"></a>')
          .text(dl.label).attr("href", dl.href)
          .appendTo @_tooltip
    else
      @_tooltip.append "<span class='empty_text'>None!</span>"

    if @_tooltip.is ".visible"
      @_tooltip.removeClass "animated visible"
      _.defer => @_tooltip.addClass "animated visible"
    else
      @_tooltip.addClass "visible animated"

    @_tooltip.css {
      left: "#{pos.left}px"
      top: "#{pos.top}px"
    }

  constructor: (el) ->
    @downloads = {}
    @el = $ el
    @_loader ||= @el.find ".loader_cell"
    @fetch_page()

    @resize_cells @cell_sizes[@cell_size]

    $(window).on "scroll resize", => @check_for_load()
    $(window).on "resize", _.debounce (=> @resize_cells @cell_sizes[@cell_size]), 200

    @el.on "click", ".downloads", (e) =>
      @show_downloads $ e.currentTarget

    $(document.body).on "click", (e) =>
      if @_tooltip?.is ".visible"
        unless $(e.target).closest("#download_tooltip, .downloads").length
          @hide_downloads()

    $(window).on "resize", =>
      @hide_downloads() if @_tooltip?.is ".visible"

  check_for_load: ->
    return if @_loading
    win = $(window)
    if win.scrollTop() + win.height() > @_loader.offset().top
      @fetch_page()

  fetch_page: ->
    @_loading = true
    opts = {
      page: @current_page
      sort: @sort
      thumb_size: @cell_size
    }

    $.get "/games?" + $.param(opts), (data) =>
      @_loader.remove()
      unless data.games
        @_loading = false
        return

      if data.games
        for game in data.games
          @render_game game

      @_loader.appendTo @el
      @_loading = false
      @current_page += 1
      @check_for_load()


