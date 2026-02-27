import { Controller } from "@hotwired/stimulus"

// Connects to data-controller="dropdown"
export default class extends Controller {
  static targets = ["menu"]

  connect() {
    console.log("Dropdown controller connected")
    // Close dropdown when clicking outside
    this.boundCloseOnClickOutside = this.closeOnClickOutside.bind(this)
    document.addEventListener("click", this.boundCloseOnClickOutside)
  }

  disconnect() {
    document.removeEventListener("click", this.boundCloseOnClickOutside)
  }

  toggle(event) {
    event.preventDefault()
    event.stopPropagation()

    const menu = this.menuTarget
    const isExpanded = menu.classList.contains("show")

    // Close all other dropdowns first
    this.closeAllDropdowns()

    if (!isExpanded) {
      menu.classList.add("show")
      this.element.querySelector('[data-dropdown-target="toggle"]').setAttribute("aria-expanded", "true")
    }
  }

  close(event) {
    if (event) {
      event.preventDefault()
    }

    const menu = this.menuTarget
    menu.classList.remove("show")
    this.element.querySelector('[data-dropdown-target="toggle"]').setAttribute("aria-expanded", "false")
  }

  closeOnClickOutside(event) {
    if (!this.element.contains(event.target)) {
      this.close()
    }
  }

  closeAllDropdowns() {
    document.querySelectorAll('[data-controller="dropdown"] .dropdown-menu.show').forEach(menu => {
      menu.classList.remove("show")
    })
    document.querySelectorAll('[data-dropdown-target="toggle"]').forEach(toggle => {
      toggle.setAttribute("aria-expanded", "false")
    })
  }
}
