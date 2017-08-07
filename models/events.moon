db = require "lapis.db"
import Model, enum, preload from require "lapis.db.model"

class Events extends Model
  @timestamp: true

  @types: enum {
    ludumdare: 1 -- old style
    ldjam: 2 -- new style
  }

  @create: (opts) =>
    super opts


