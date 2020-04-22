let openPickers = []
let bodyListener = null

export function bindMenusBodyClick() {
  bodyListener = function(e) {
    let picker = e.target.closest(".dropdown_picker")
    if (!picker) {
      picker = e.target.closest(".toggle_dropdown")
    }

    if (!picker) {
      openPickers.forEach(p => p.close())
    }
  }

  document.body.addEventListener("click", bodyListener)
}

export function removeClosedMenu(p) {
  if (openPickers.includes(p)) {
    openPickers = openPickers.filter(other => other != p)
  }
}

// push it and close all the others
export function pushOpenMenu(p) {
  openPickers.forEach(other => {
    if (p != other) {
      other.close()
    }
  })

  if (!openPickers.includes(p)) {
    openPickers = openPickers.concat([p])
  }
}

export function closeAllMenus() {
  openPickers.forEach(p => p.close())
}


