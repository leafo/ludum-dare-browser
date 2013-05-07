
import config from require "lapis.config"

config "development", ->
  num_workers 1
  num_connections 1024
  code_cache "off"

  postgresql_url "postgres://postgres:@127.0.0.1/ludumdare"

config "production", ->
  port 80
  num_workers 8
  num_connections 1024*8
  code_cache "on"

  postgresql_url "postgres://postgres:@127.0.0.1/ludumdare"
