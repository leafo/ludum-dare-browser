import Model from require "lapis.db.model"

class Collections extends Model
  @primary_key: {"name", "comp", "uid"}

  @add_game: (name, comp, game) =>
    uid = game.uid
    params = { :name, :comp, :uid }
    unless @find params
      @create params
