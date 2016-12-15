window.I ||= {}

_.templateSettings = {
  interpolate : /\{\{(.+?)\}\}/g
}

cdn_prefix = {
}

make_dropdown = (el) ->
  popup = el.find ".select_popup"
  t = null

  close_picker = =>
    clearTimeout t if t
    el.removeClass "open"
    t = setTimeout =>
      popup.css { left: "", top: ""}
      t = null
    , 200

  set_value = (label) =>
    el.find(".current_option .label").html label

  el.on "i:choose", (e, value) =>
    opt = el.find ".option[data-value='#{value}']"
    set_value opt.text() if opt.length
    false

  el.on "click", ".current_option", (e) =>
    if el.is ".open"
      close_picker()
    else
      clearTimeout t if t
      t = null

      target = $(e.currentTarget)
      pos = target.position()
      el.addClass "open"
      popup.css {
        left: "#{Math.floor pos.left + target.outerWidth() - popup.width() / 2}px"
        top: "#{pos.top + target.height()}px"
      }

  el.on "click", ".option", (e) =>
    option = $(e.currentTarget)
    value = option.data "value"
    set_value option.text()
    close_picker()
    el.trigger "i:change", [value]

  $(window.document).on "click", (e) =>
    if el.is ".open"
      unless $(e.target).closest(el).length
        close_picker()

  $(window).on "resize", =>
    close_picker() if el.is ".open"

  el

class I.GamePage
  setup_collection_picker: ->
    @collection_picker = make_dropdown($ "#collection_picker")
      .on "i:change", (e, collection) =>
        @list.collection = collection
        @list.reset()

  setup_sort_picker: ->
    @sort_picker = make_dropdown($ "#sort_picker")
      .on "i:change", (e, mode) =>
        @list.sort = mode
        @list.reset()

  set_size_picker: (val) ->
    @size_picker ||= $ "#size_picker"
    current = @size_picker.find(".picker").removeClass("current")
      .filter("[data-size='#{val}']").addClass "current"

    unless current.length
      # set default
      current.end().filter("[data-size='#{I.GameList::cell_size}']")
        .addClass("current")

  setup_size_picker: ->
    @size_picker ||= $ "#size_picker"
    pickers = @size_picker.find ".picker"
    @size_picker.on "click", ".picker", (e) =>
      pickers.removeClass "current"
      p = $(e.currentTarget).addClass "current"
      @list.set_size p.data "size"

  constructor: ->
    @toolbar = $("#toolbar")

    @toolbar.on "change", "input.toggle_details", (e) =>
      checked = $(e.currentTarget).prop "checked"
      @list.el.toggleClass "show_labels", checked
      @list.save_params()

    @setup_size_picker()
    @setup_sort_picker()
    @setup_collection_picker()

    window.thelist = @list = new I.GameList $("#game_list"), @

    if window.location?.hash.match /\bdetails=true\b/
      @toolbar.find("input.toggle_details").prop "checked", true
      @list.el.addClass "show_labels"


class I.GameList
  current_page: 0
  aspect_ratio: 300/240
  cell_size: "medium"
  sort: "votes"
  cdn_prefix: ""
  collection: "all"

  cell_sizes: {
    small: 180 # 220
    medium: 300 # 340
    large: 500 # 360
  }

  load_params: ->
    if m = window.location?.hash.match /\bsort=(.+?)\b/
      @sort = m[1]
      @parent.sort_picker.trigger "i:choose", @sort

    if m = window.location?.hash.match /\bcollection=(.+?)\b/
      @collection = m[1]
      @parent.collection_picker.trigger "i:choose", @collection

    if m = window.location?.hash.match /\bthumb_size=(.+?)\b/
      if @cell_sizes[m[1]]
        @cell_size = m[1]
        @parent.set_size_picker @cell_size

  save_params: ->
    opts = {
      sort: @sort
      thumb_size: @cell_size
      collection: @collection
    }

    delete opts.sort if @sort == @constructor::sort
    delete opts.thumb_size if @cell_size == @constructor::cell_size
    delete opts.collection if @collection == @constructor::collection

    if @el.is ".show_labels"
      opts.details = true

    window.location.hash = $.param opts

  set_size: (size) ->
    size = "medium" if !@cell_sizes[size]
    @cell_size = size
    @reset()
    @resize_cells @cell_sizes[size]

  reset: ->
    @save_params()
    @current_page = 0
    @el.empty().append @_loader
    @fetch_page()

  resize_cells: (expected_width) ->
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

  render_game: (game) ->
    @downloads[game.uid] = game.downloads

    if @cdn_prefix
      game.screenshot_url = @cdn_prefix + game.screenshot_url

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

  constructor: (el, @parent) ->
    @downloads = {}
    @el = $ el
    @_loader ||= @el.find ".loader_cell"
    @load_params()
    @fetch_page()

    @resize_cells @cell_sizes[@cell_size]

    disable_details = _.debounce (=> @el.removeClass("details_enabled")), 400, true
    enable_details = _.debounce (=> @el.addClass("details_enabled")), 400

    $(window).on "scroll resize", =>
      disable_details()
      enable_details()
      @check_for_load()

    $(window).on "resize", _.debounce (=> @resize_cells @cell_sizes[@cell_size]), 200

    @el.on "click", ".downloads", (e) =>
      @show_downloads $ e.currentTarget

    $(document.body).on "click", (e) =>
      if @_tooltip?.is ".visible"
        unless $(e.target).closest("#download_tooltip, .downloads").length
          @hide_downloads()

    $(window).on "resize", =>
      @hide_downloads() if @_tooltip?.is ".visible"

    if prefix = cdn_prefix[window.location.host]
      @cdn_prefix = prefix

  check_for_load: ->
    return if @_loading or !@_loader.parent().length
    win = $(window)
    if win.scrollTop() + win.height() > @_loader.offset().top
      @fetch_page()

  fetch_page: ->
    @_loading = true
    @_rand ||= Math.floor Math.random() * 100000
    opts = {
      page: @current_page
      sort: @sort
      thumb_size: @cell_size
      collection: @collection
      seed: if @sort == "random" then @_rand
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


