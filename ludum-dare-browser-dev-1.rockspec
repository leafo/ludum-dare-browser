package = "ludum-dare-browser"
version = "dev-1"

source = {
  url = "git+https://github.com/leafo/streak.club.git"
}

description = {
  summary = "A website that shows all Ludum Dare submissions",
  homepage = "https://ludumdare.itch.io",
  license = "unlicensed"
}

dependencies = {
  "lua ~> 5.1",
  "moonscript",
  -- "busted", -- only in test

  "lapis >= 1.9",
  "magick >= 1.6",
  "tableshape >= 2.2",
  "http >= 0.4", -- needed for command line http requests
  "base58",

  "lapis-systemd >= 1.0",
  "web_sanitize >= 1.2",
}

build = {
  type = "none"
}
