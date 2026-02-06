import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["prompt", "title", "given", "when", "then", "button", "spinner"]
  static values = { planId: Number }

  async generate(event) {
    event.preventDefault()

    const prompt = this.promptTarget.value.trim()
    if (!prompt) {
      alert("Digite uma descrição do cenário que deseja testar.")
      return
    }

    this.buttonTarget.disabled = true
    this.spinnerTarget.classList.remove("hidden")

    try {
      const response = await fetch(`/test_plans/${this.planIdValue}/test_scenarios/generate`, {
        method: "POST",
        headers: {
          "Content-Type": "application/json",
          "X-CSRF-Token": document.querySelector('meta[name="csrf-token"]').content
        },
        body: JSON.stringify({ prompt: prompt })
      })

      const data = await response.json()

      if (!response.ok) {
        alert(data.error || "Erro ao gerar cenário.")
        return
      }

      this.titleTarget.value = data.title || ""
      this.givenTarget.value = data.given || ""
      this.whenTarget.value = data.when_step || ""
      this.thenTarget.value = data.then_step || ""

      this.promptTarget.value = ""
    } catch (error) {
      console.error("Erro ao gerar cenário:", error)
      alert("Erro ao comunicar com a IA. Tente novamente.")
    } finally {
      this.buttonTarget.disabled = false
      this.spinnerTarget.classList.add("hidden")
    }
  }
}
