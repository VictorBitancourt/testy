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
    const flash = document.createElement("div")
    flash.className = "flash flash--notice"
    flash.setAttribute("data-controller", "flash")
    flash.innerHTML = '<div class="flash__inner">You found it. Now get back to testing :)</div>'
    document.body.appendChild(flash)
  }
}
