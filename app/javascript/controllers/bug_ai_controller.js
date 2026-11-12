import { Controller } from "@hotwired/stimulus"
import { t } from "i18n_helper"

// Sends pasted bug notes to the AI and fills the bug form with the draft for review.
export default class extends Controller {
  static targets = ["text", "button", "spinner", "result"]
  static values = { url: String }

  async draft(event) {
    event.preventDefault()

    const text = this.textTarget.value.trim()
    if (!text) {
      alert(t("bug_ai.enter_text"))
      return
    }

    this.buttonTarget.disabled = true
    this.spinnerTarget.classList.remove("hidden")
    this.resultTarget.classList.add("hidden")

    try {
      const response = await fetch(this.urlValue, {
        method: "POST",
        headers: {
          "Content-Type": "application/json",
          "Accept": "application/json",
          "X-CSRF-Token": document.querySelector('meta[name="csrf-token"]').content
        },
        body: JSON.stringify({ text: text })
      })
      const data = await response.json()

      if (!response.ok) {
        alert(data.error || t("bug_ai.error"))
        return
      }

      this.fill(data.bug)
      this.resultTarget.textContent = t("bug_ai.filled")
      this.resultTarget.classList.remove("hidden")
    } catch (error) {
      console.error("Error drafting bug:", error)
      alert(t("ai_generate.error_communication"))
    } finally {
      this.buttonTarget.disabled = false
      this.spinnerTarget.classList.add("hidden")
    }
  }

  fill(bug) {
    for (const [field, value] of Object.entries(bug)) {
      const input = document.querySelector(`[name="bug[${field}]"]`)
      if (input && value) input.value = value
    }

    // The optional fields (steps, results) start hidden on a new bug.
    const optional = document.querySelector('[data-bug-form-target="optionalFields"]')
    if (optional?.classList.contains("hidden")) {
      optional.classList.remove("hidden")
      const toggleText = document.querySelector('[data-bug-form-target="toggleText"]')
      if (toggleText) toggleText.textContent = t("bug_form.hide_details")
    }

    document.querySelector('[name="bug[title]"]')?.scrollIntoView({ behavior: "smooth", block: "center" })
  }
}
