import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["menu"]
  static values = { key: { type: String, default: "t" } }

  connect() {
    this.handleKeydown = this.handleKeydown.bind(this)
    this.handleClickOutside = this.handleClickOutside.bind(this)
    document.addEventListener("keydown", this.handleKeydown)
    document.addEventListener("click", this.handleClickOutside)
  }

  disconnect() {
    document.removeEventListener("keydown", this.handleKeydown)
    document.removeEventListener("click", this.handleClickOutside)
  }

  toggle() {
    this.menuTarget.classList.toggle("hidden")
  }

  handleKeydown(event) {
    if (event.target.tagName === "INPUT" || event.target.tagName === "TEXTAREA") return

    if (event.key.toLowerCase() === this.keyValue.toLowerCase()) {
      event.preventDefault()
      this.toggle()
    }

    if (event.key === "Escape") {
      this.menuTarget.classList.add("hidden")
    }
  }

  handleClickOutside(event) {
    if (!this.element.contains(event.target)) {
      this.menuTarget.classList.add("hidden")
    }
  }
}
