import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  connect() {
    this.clickCount = 0
    this.fallen = false
  }

  click(event) {
    if (this.fallen) return

    this.clickCount++

    if (this.clickCount >= 50) {
      event.stopPropagation()
      this.fall()
    }
  }

  fall() {
    this.fallen = true
    this.element.style.transformOrigin = "bottom left"
    this.element.style.animation = "sign-fall 4s cubic-bezier(0.22, 1, 0.36, 1) forwards"

    this.element.addEventListener("animationend", () => this.showMessage(), { once: true })
  }

  showMessage() {
    const toast = document.createElement("div")
    toast.className = "flash-message fixed top-4 right-4 bg-fz-green-dark text-white px-6 py-3 rounded-lg shadow-lg z-50 animate-fade-in"
    toast.textContent = "You found it. Now get back to testing :)"
    document.body.appendChild(toast)

    setTimeout(() => {
      toast.style.transition = "opacity 0.5s ease-out, transform 0.5s ease-out"
      toast.style.opacity = "0"
      toast.style.transform = "translateX(100px)"
      setTimeout(() => toast.remove(), 500)
    }, 4000)
  }
}
