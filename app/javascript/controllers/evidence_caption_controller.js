import { Controller } from "@hotwired/stimulus"

// Saves an evidence caption as soon as the field changes (blur or Enter).
export default class extends Controller {
  static targets = ["input"]

  async save(event) {
    event.preventDefault()
    this.element.classList.remove("evidence-caption--saved", "evidence-caption--error")

    try {
      const response = await fetch(this.element.action, {
        method: "PATCH",
        headers: {
          "Content-Type": "application/json",
          "Accept": "application/json",
          "X-CSRF-Token": document.querySelector('meta[name="csrf-token"]')?.content
        },
        body: JSON.stringify({ caption: this.inputTarget.value })
      })
      this.element.classList.add(response.ok ? "evidence-caption--saved" : "evidence-caption--error")
    } catch {
      this.element.classList.add("evidence-caption--error")
    }
  }

  // The scenario card is draggable, which would swallow text selection in the field.
  lockDrag() {
    this.card = this.element.closest('[draggable="true"]')
    if (this.card) this.card.draggable = false
  }

  unlockDrag() {
    if (this.card) this.card.draggable = true
    this.card = null
  }
}
