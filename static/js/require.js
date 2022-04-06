
// this module is use to provide a very basic interface for inserterting static data that can be imported

// esbuild compiles with --external:ld/events, which will leave any import
// statements alone for that module

let modules = {}

window.define = function(module, obj) {
  modules[module] = obj
}
window.require = function(module) {
  return modules[module]
}
