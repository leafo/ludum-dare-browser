import use_test_server from require "lapis.spec"
import request from require "lapis.spec.server"

describe "ludumdare", ->
  use_test_server!

  import Games, Collections from require "spec.models"

  before_each ->

  it "requests root", ->
    status = request "/"
    assert.same 200, status

  it "requests empty games", ->
    status, res = request "/games", {
      expect: "json"
    }

    assert.same 200, status
    assert.same {}, res

