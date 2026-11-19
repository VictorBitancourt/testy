import { Controller } from "@hotwired/stimulus"
import { t } from "i18n_helper"

// Translates the [data-translatable] fields inside the scope element (the
// closest match of the scope selector) into English with the AI and fills them
// in for review. Nothing is saved.
export default class extends Controller {
  static targets = ["button", "status"]
  static values = { url: String, scope: String }

  async translate(event) {
    event.preventDefault()

    const inputs = this.inputs().filter(input => input.value.trim())
    if (inputs.length === 0) {
      alert(t("ai_translate.nothing"))
      return
    }

    const fields = Object.fromEntries(inputs.map(input => [input.name, input.value]))
    this.buttonTarget.disabled = true
    this.showStatus(t("ai_translate.working"))

    try {
      const response = await fetch(this.urlValue, {
        method: "POST",
        headers: {
          "Content-Type": "application/json",
          "Accept": "application/json",
          "X-CSRF-Token": document.querySelector('meta[name="csrf-token"]')?.content
        },
        body: JSON.stringify({ fields })
      })
      const data = await response.json()

      if (!response.ok) {
        this.showStatus("")
        alert(data.error || t("ai_translate.error"))
        return
      }

      for (const input of inputs) {
        const value = data.fields[input.name]
        if (value) input.value = value
      }
      this.showStatus(t("ai_translate.done"))
    } catch (error) {
      console.error("Error translating:", error)
      this.showStatus("")
      alert(t("ai_generate.error_communication"))
    } finally {
      this.buttonTarget.disabled = false
    }
  }

  inputs() {
    const scope = this.element.closest(this.scopeValue) || this.element
    return Array.from(scope.querySelectorAll("[data-translatable]"))
  }

  showStatus(text) {
    if (!this.hasStatusTarget) return
    this.statusTarget.textContent = text
    this.statusTarget.classList.toggle("hidden", !text)
  }
}
