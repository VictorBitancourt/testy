import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static values = { key: String }

  connect() {
    this.handleKeydown = this.handleKeydown.bind(this)
    document.addEventListener("keydown", this.handleKeydown)
  }

  disconnect() {
    document.removeEventListener("keydown", this.handleKeydown)
  }

  handleKeydown(event) {
    // Ignore if user is typing in an input/textarea
    if (event.target.tagName === "INPUT" || event.target.tagName === "TEXTAREA") {
      return
    }

    // Leave browser shortcuts such as Cmd+W / Ctrl+N alone
    if (event.metaKey || event.ctrlKey || event.altKey) return

    if (event.key.toLowerCase() === this.keyValue.toLowerCase()) {
      event.preventDefault()
      this.element.click()
    }
  }
}
