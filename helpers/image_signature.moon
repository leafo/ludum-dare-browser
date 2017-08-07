
import encode_base58 from require "base58"

image_signature = (path, len=10, secret=require"secret.keys".image_key) ->
  str = encode_base58 ngx.hmac_sha1 secret, path
  str = str\sub 1, len if len
  str

{:image_signature}
