
let modules = {}

window.define = function(module, obj) {
  modules[module] = obj
}
window.require = function(module) {
  return modules[module]
}
