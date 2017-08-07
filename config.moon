
import config from require "lapis.config"

config {"development", "production", "test"}, ->
  comp_id 39

  num_workers 1
  num_connections 1024

  bypass_image_cache "0"
  bypass_page_cache "0"

config "development", ->
  code_cache "off"
  daemon "off"

  postgres {
    backend: "pgmoon"
    database: "ludumdare"
  }

  bypass_page_cache "1"

config "production", ->
  port 10000
  num_workers 2
  num_connections 1024*8
  code_cache "on"
  daemon "on"

  postgres {
    backend: "pgmoon"
    database: "ludumdare"
  }

  systemd {
    user: true
  }

config "test", ->
  code_cache "on"
  daemon "off"

  postgres {
    database: "ludumdare_test"
  }

