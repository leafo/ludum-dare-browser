window.I ||= {}

_.templateSettings = {
  interpolate : /\{\{(.+?)\}\}/g
}

class I.GameList
  current_page: 0
  aspect_ratio: 300/240
  cell_size: "medium"

  cell_sizes: {
    small: 180
    medium: 300 # 340
    large: 500
  }

  resize_cells: (expected_width) =>
    real_width = expected_width + 20 # cell margin
    page_width = @el.width()

    console.log page_width

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
    console.log "#{new_width}px, #{new_height}px"
    @_style = $("<style type='text/css'>#{css}</style>").appendTo $("head")

  render_game: (game) =>
    @_tpl ||= _.template $("#game_template").html()
    game_el = $($.trim @_tpl game).appendTo @el
    $("<img />").attr("src", game.screenshot_url).on "load", =>
      game_el.removeClass "image_loading"

  constructor: (el) ->
    @el = $ el
    @_loader ||= @el.find ".loader_cell"
    @fetch_page()

    cell_size = @cell_sizes[@cell_size]
    @resize_cells cell_size

    $(window).on "scroll resize", => @check_for_load()
    $(window).on "resize", _.debounce (=> @resize_cells cell_size), 200

  check_for_load: ->
    return if @_loading
    win = $(window)
    if win.scrollTop() + win.height() > @_loader.offset().top
      @fetch_page()

  fetch_page: ->
    @_loading = true
    $.get "/games?" + $.param(page: @current_page), (data) =>
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


