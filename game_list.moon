import P, C, Cg, S, Ct, R from require "lpeg"

trim = (str) -> tostring(str)\match "^%s*(.-)%s*$"

local _http
http = ->
  unless _http
    _http = require "socket.http"
  _http

set_http = (h) -> _http = h

decode_entities = do
  entities = { amp: '&', gt: '>', lt: '<', quot: '"', apos: "'" }
  -- entities = require "entities"
  (str) ->
    (str\gsub '&(.-);', (tag) ->
      if entities[tag]
        entities[tag]
      elseif chr = tag\match "#(%d+)"
        string.char tonumber chr
      else
        '&'..tag..';')

parse_rows = do
  patt = "<tr>" * C (1 - (P"<tr>" + P"</table>"))^0
  patt = Ct (patt + 1)^0
  patt\match

parse_row = do
  white = S"\n\t\r "^0
  close = white * P"<td>"
  cell = P"<td>" * white * C (1 - close)^0
  patt = Ct (cell + 1)^0
  patt\match

parse_links = do
  white = S"\n\t\r "^0

  alphanum = R "az", "AZ", "09"
  word = (alphanum + S"._-")^1
  value = C(word) + P'"' * C((1 - P'"')^0) * P'"' + P"'" * C((1 - P"'")^0) * P"'"

  open = "<a" * ((P"href" * white * P"=" * value + 1) - ">")^0 * ">"
  close = white * "</a>"
  inside = white * C((1 - close)^0)
  link = Ct Cg(open / decode_entities, "href") * Cg(inside / decode_entities, "label")

  links = Ct (link + 1)^0

  links\match

parse_game = (text) ->
  cells = parse_row text
  return nil unless cells and #cells > 0

  game_link = unpack parse_links cells[1]
  return nil unless game_link

  uid = game_link.href\match "uid=(%d+)"
  return nil unless uid

  {
    title: game_link.label
    url: game_link.href
    user: decode_entities cells[2]
    uid: uid
    votes_received: tonumber cells[4]
    votes_given: tonumber cells[5]
    downloads: parse_links cells[3]
  }

parse_list = (content) ->
  games = for row in *parse_rows content
    game = parse_game row
    continue unless game
    game

  games

fetch_list = (ld=26)->
  url = "http://ludumdare.com/compo/ludum-dare-#{ld}/?action=misc_links"
  res, status = http!.request url
  assert status == 200, "#{url} failed with #{status}"

  parse_list res


-- get screenshots, determine if jam or comp
fetch_game = (uid, ld=26) ->
  url = "http://ludumdare.com/compo/ludum-dare-#{ld}/?action=preview&uid=#{uid}"
  res, status = http!.request url
  assert status == 200, "#{url} failed with #{status}"

  screenshots = for link in *parse_links res
    continue unless link.href\match "shot%d+"
    link.href

  is_jam = res\match("Jam Entry") and true or false
  { :uid, :screenshots, :is_jam }

if ... == "games"
  -- games = fetch_list!

  file = io.open "games.html"
  res = with file\read "*a"
    file\close!

  games = parse_list res
  -- require "moon"
  -- moon.p games

if ... == "game"
  game = fetch_game 22909
  require "moon"
  moon.p game

{ :fetch_list, :fetch_game, :set_http }
