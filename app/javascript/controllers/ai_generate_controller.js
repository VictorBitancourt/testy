import { Controller } from "@hotwired/stimulus"
import { t } from "i18n_helper"

export default class extends Controller {
  static targets = ["prompt", "button", "spinner", "result"]
  static values = { planId: Number }

  async generate(event) {
    event.preventDefault()

    const prompt = this.promptTarget.value.trim()
    if (!prompt) {
      alert(t('ai_generate.enter_description'))
      return
    }

    this.buttonTarget.disabled = true
    this.spinnerTarget.classList.remove("hidden")
    this.resultTarget.classList.add("hidden")

    try {
      const response = await fetch(`/test_plans/${this.planIdValue}/ai_generation`, {
        method: "POST",
        headers: {
          "Content-Type": "application/json",
          "X-CSRF-Token": document.querySelector('meta[name="csrf-token"]').content
        },
        body: JSON.stringify({ prompt: prompt })
      })

      const data = await response.json()

      if (!response.ok) {
        alert(data.error || t('ai_generate.error_generating'))
        return
      }

      this.resultTarget.textContent = t('ai_generate.scenarios_created', { count: data.count })
      this.resultTarget.classList.remove("hidden")
      this.promptTarget.value = ""

      setTimeout(() => window.location.reload(), 1200)
    } catch (error) {
      console.error("Error generating scenarios:", error)
      alert(t('ai_generate.error_communication'))
    } finally {
      this.buttonTarget.disabled = false
      this.spinnerTarget.classList.add("hidden")
    }
  }
}
