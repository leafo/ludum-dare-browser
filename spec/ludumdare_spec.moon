import use_test_env from require "lapis.spec"

import types from require "tableshape"

describe "clients.ludumdare.", ->
  use_test_env!

  import Games, CollectionGames from require "spec.models"

  it "parses misc links", ->
    file = io.open("spec/data/ld-37.html")\read "*a"
    import parse_list from require "clients.ludumdare"
    out = parse_list file

    assert.same 2390, #out
    list_shape = types.array_of types.shape {
      votes_received: types.integer
      votes_given: types.integer

      uid: types.string
      title: types.string
      url: types.string
      user: types.string

      downloads: types.array_of types.shape {
        href: types.string
        label: types.string
      }
    }

    assert list_shape out

    assert.same {
      votes_received: 3
      uid: "125708"
      title: "Find The One Peaceful Room"
      url: "?action=preview&uid=125708"
      votes_given: 0
      user: "eric186"
      downloads: {
        {
          href: "https://www.dropbox.com/s/v61ptr30aqsdyjw/WebGL.zip?dl=0"
          label: "Web"
        }
        {
          href: "https://www.dropbox.com/s/49kvc1htcphup76/Windows.zip?dl=0"
          label: "Windows"
        }
        {
          href: "https://www.dropbox.com/s/2yfn94ldvri6wu5/Mac.zip?dl=0"
          label: "OS/X"
        }
        {
          href: "https://www.dropbox.com/s/0zonvgqpft12tjk/Linux.zip?dl=0"
          label: "Linux"
        }
      }
    }, out[1]

  it "parses game page", ->
    file = io.open("spec/data/ld-37-game.html")\read "*a"
    import parse_game_page from require "clients.ludumdare"
    out = parse_game_page file
    assert.same {
      is_jam: false
      screenshots: {
        "http://ludumdare.com/compo/wp-content/compo2/593814/3479-shot0-1481510638.png"
      }
    }, out

