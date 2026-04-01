import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["input", "suggestions"]
  static values = { field: String }

  connect() {
    this.timeout = null
    document.addEventListener("click", this.closeSuggestions)
  }

  disconnect() {
    document.removeEventListener("click", this.closeSuggestions)
  }

  onInput() {
    clearTimeout(this.timeout)
    const query = this.inputTarget.value.trim()
    if (query.length < 1) {
      this.hideSuggestions()
      return
    }
    this.timeout = setTimeout(() => this.fetchSuggestions(query), 200)
  }

  async fetchSuggestions(query) {
    const response = await fetch(`/bugs/tag_suggestions?field=${this.fieldValue}&q=${encodeURIComponent(query)}`)
    const tags = await response.json()
    this.showSuggestions(tags)
  }

  showSuggestions(tags) {
    if (tags.length === 0) {
      this.hideSuggestions()
      return
    }

    this.suggestionsTarget.innerHTML = ""
    tags.forEach(tag => {
      const btn = document.createElement("button")
      btn.type = "button"
      btn.dataset.action = "click->bug-tag#select"
      btn.dataset.tag = tag
      btn.className = "suggestions__item"
      btn.textContent = tag
      this.suggestionsTarget.appendChild(btn)
    })
    this.suggestionsTarget.classList.remove("hidden")
  }

  hideSuggestions() {
    this.suggestionsTarget.classList.add("hidden")
    this.suggestionsTarget.innerHTML = ""
  }

  select(event) {
    event.preventDefault()
    this.inputTarget.value = event.currentTarget.dataset.tag
    this.hideSuggestions()
    this.inputTarget.focus()
  }

  closeSuggestions = (event) => {
    if (!this.element.contains(event.target)) {
      this.hideSuggestions()
    }
  }
}
