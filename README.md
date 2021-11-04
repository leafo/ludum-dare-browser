# Ludum Dare Games Browser

<https://ludumdare.itch.io>

![test](https://github.com/leafo/ludum-dare-browser/workflows/test/badge.svg)

A website for browsing Ludum Dare games. Built with [Lapis][2] and
[MoonScript][1] on the backend, [Preact][3] on the frontend.

![ScreenShot](http://leafo.net/shotsnb/2013-05-11_23-26-37.png)


## How to update LD Jam version

* Update `data/events.moon`, pull event ID from https://api.ldjam.com/vx/node/feed/9/parent/event
* Update `comp_id` to latest numeric version for set default event
* Run `cmd/refresh_events.moon` to synchronize `data/events.moon` with database

These actions should be run immediately and also run in cron while new games are being submitted:

* Go to `https://ludumdare.itch.io/admin/scrape_games`
* Go to `https://ludumdare.itch.io/admin/make_collections`


 [1]: https://moonscript.org
 [2]: https://leafo.net/lapis
 [3]: https://preactjs.com/



