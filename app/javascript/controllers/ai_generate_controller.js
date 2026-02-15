import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["prompt", "button", "spinner", "result"]
  static values = { planId: Number }

  async generate(event) {
    event.preventDefault()

    const prompt = this.promptTarget.value.trim()
    if (!prompt) {
      alert("Enter a description of the feature you want to test.")
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
        alert(data.error || "Error generating scenarios.")
        return
      }

      this.resultTarget.textContent = `${data.count} scenarios created successfully!`
      this.resultTarget.classList.remove("hidden")
      this.promptTarget.value = ""

      setTimeout(() => window.location.reload(), 1200)
    } catch (error) {
      console.error("Error generating scenarios:", error)
      alert("Error communicating with AI. Please try again.")
    } finally {
      this.buttonTarget.disabled = false
      this.spinnerTarget.classList.add("hidden")
    }
  }
}
