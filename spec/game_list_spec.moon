import use_test_env from require "lapis.spec"

import types from require "tableshape"

describe "ludumdare.game_list", ->
  use_test_env!

  import Games, Collections from require "spec.models"

  it "parses misc links", ->
    file = io.open("spec/data/ld-37.html")\read "*a"
    out = require("game_list").parse_list file

    assert.same 2390, #out
    game_shape = types.shape {
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

    assert game_shape out[1]

  it "parses game page", ->


