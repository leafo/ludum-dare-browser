db = require "lapis.db"
import Model from require "lapis.db.model"


class CollectionGames extends Model
  @primary_key: {"name", "game_id"}

  @relations: {
    {"game", belongs_to: "Games"}
    {"event", belongs_to: "Events"}
  }

  @COLLECTIONS: {
    love: { "Love", {"love", "love2d"} }
    python: { "Python", {"python", "pygame"} }
    unity: { "Unity", {"unity"} }
    xna: { "XNA", {"xna"} }
    flash: { "Flash", {"flash", "swf"} }
    html5: { "HTML5", {"html5"} }
    java: { "Java", {"java", "jar"} }

    linux: { "Linux", {"linux"} }
    windows: { "Windows", {"windows", "win32"} }
    osx: { "OSX", {"os/x", "osx", "os x"} }
    android: { "Android", {"android"} }
  }

  @create: (opts) =>
    import insert_on_conflict_ignore from require "helpers.model"
    insert_on_conflict_ignore @, opts

  -- return the collections that match this game
  @scan_game: (game) =>
    assert ngx, "must run in nginx"
    match = ngx.re.match

    out = {}
    for collection_name, {_, words} in pairs @COLLECTIONS
      continue unless game.downloads

      regex = "\\b(?:#{table.concat words, "|"})\\b"
      for d in *game.downloads
        if match(d.href, regex, "i") or match(d.label, regex, "i")
          table.insert out, collection_name
          break

    out

