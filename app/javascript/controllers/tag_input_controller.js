import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["input", "suggestions"]

  connect() {
    this.timeout = null
    document.addEventListener("click", this.closeSuggestions)
  }

  disconnect() {
    document.removeEventListener("click", this.closeSuggestions)
  }

  onInput() {
    clearTimeout(this.timeout)
    const query = this.currentTag()
    if (query.length < 1) {
      this.hideSuggestions()
      return
    }
    this.timeout = setTimeout(() => this.fetchSuggestions(query), 200)
  }

  async fetchSuggestions(query) {
    const response = await fetch(`/tags/autocomplete?q=${encodeURIComponent(query)}`)
    const tags = await response.json()
    this.showSuggestions(tags)
  }

  showSuggestions(tags) {
    if (tags.length === 0) {
      this.hideSuggestions()
      return
    }

    this.suggestionsTarget.innerHTML = tags
      .map(tag => `<button type="button" data-action="click->tag-input#select" data-tag="${tag}" class="block w-full text-left px-3 py-2 text-sm text-ink-darkest hover:bg-fz-violet-darkest hover:text-fz-violet-light transition">${tag}</button>`)
      .join("")
    this.suggestionsTarget.classList.remove("hidden")
  }

  hideSuggestions() {
    this.suggestionsTarget.classList.add("hidden")
    this.suggestionsTarget.innerHTML = ""
  }

  select(event) {
    event.preventDefault()
    const selectedTag = event.currentTarget.dataset.tag
    const parts = this.inputTarget.value.split(",")
    parts.pop()
    parts.push(selectedTag)
    this.inputTarget.value = parts.join(", ") + ", "
    this.hideSuggestions()
    this.inputTarget.focus()
  }

  currentTag() {
    const parts = this.inputTarget.value.split(",")
    return parts[parts.length - 1].trim()
  }

  closeSuggestions = (event) => {
    if (!this.element.contains(event.target)) {
      this.hideSuggestions()
    }
  }
}
