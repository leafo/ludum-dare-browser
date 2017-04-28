
->
  params = for k,v in pairs ngx.req.get_uri_args!
    v = unpack v if type(v) == "table"
    "#{k}:#{v}"

  table.sort params
  table.concat params, "-"
