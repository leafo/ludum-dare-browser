
import config from require "lapis.config"

config "development", ->
  num_workers 1
  num_connections 1024
  code_cache "off"
  daemon "off"

  postgresql_url "postgres://postgres:@127.0.0.1/ludumdare"

config "production", ->
  port 10000
  num_workers 2
  num_connections 1024*8
  code_cache "on"
  daemon "on"

  postgresql_url "postgres://postgres:@127.0.0.1/ludumdare"
