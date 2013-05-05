
import config from require "lapis.config"

config "development", ->
  num_workers 1
  code_cache "off"

  postgresql_url "postgres://postgres:@127.0.0.1/ludumdare"
  host "localhost.com"
