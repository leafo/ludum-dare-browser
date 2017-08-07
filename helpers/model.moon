
db = require "lapis.db"
import encode_values, encode_assigns from require "lapis.db"
import insert, concat from table

insert_on_conflict_ignore = (model, opts) ->
  import encode_values, encode_assigns from require "lapis.db"

  full_insert = {}

  if opts
    for k,v in pairs opts
      full_insert[k] = v

  if model.timestamp
    d = db.format_date!
    full_insert.created_at = d
    full_insert.updated_at = d

  buffer = {
    "insert into "
    db.escape_identifier model\table_name!
    " "
  }

  encode_values full_insert, buffer

  insert buffer, " on conflict do nothing returning *"

  q = concat buffer
  res = db.query q

  if res.affected_rows and res.affected_rows > 0
    model\load res[1]
  else
    nil, res


insert_on_conflict_update = (model, primary, create, update) ->
  full_insert = {k,v for k,v in pairs primary}

  if create
    for k,v in pairs create
      full_insert[k] = v

  full_update = update or {k,v for k,v in pairs full_insert when not primary[k]}

  if model.timestamp
    d = db.format_date!
    full_insert.created_at = d
    full_insert.updated_at = d
    full_update.updated_at = d

  buffer = {
    "insert into "
    db.escape_identifier model\table_name!
    " "
  }

  encode_values full_insert, buffer

  insert buffer, " on conflict ("

  for k in pairs primary
    insert buffer, db.escape_identifier k
    insert buffer, ", "

  buffer[#buffer] = ") do update set " -- remove ,
  encode_assigns full_update, buffer

  insert buffer, " returning *"

  q = concat buffer
  res = db.query q

  if res.affected_rows and res.affected_rows > 0
    model\load res[1]
  else
    nil, res

values_equivalent = (a,b) ->
  return true if a == b

  if type(a) == "table" and type(b) == "table"
    seen_keys = {}

    for k,v in pairs a
      seen_keys[k] = true
      return false unless values_equivalent v, b[k]

    for k,v in pairs b
      continue if seen_keys[k]
      return false unless values_equivalent v, a[k]

    true
  else
    false

-- remove fields that haven't changed
filter_update = (model, update) ->
  for key,val in pairs update
    if model[key] == val
      update[key] = nil

    if val == db.NULL and model[key] == nil
      update[key] = nil

    if type(val) == "table"
      if values_equivalent model[key], val
        update[key] = nil

  update


{ :insert_on_conflict_update, :insert_on_conflict_ignore, :filter_update }
