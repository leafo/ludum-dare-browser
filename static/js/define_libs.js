requirejs.config({
  baseUrl: "static/lib"
})

define("window", window);
define("preact", preact);
define("preactRouter", function() { return preactRouter });
