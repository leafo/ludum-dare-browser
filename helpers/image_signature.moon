
for_url = (str) ->
  (str\gsub "[/+]", {
    "+": "%2B"
    "/": "%2F"
  })


image_signature = (path, _url=true, len=10, secret=require"secret.keys".image_key) ->
  str = ngx.encode_base64 ngx.hmac_sha1 secret, path
  str = str\sub 1, len if len
  str = for_url str if _url
  str

{:image_signature}
