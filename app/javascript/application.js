// Configure your import map in config/importmap.rb. Read more: https://github.com/rails/importmap-rails
import "@hotwired/turbo-rails"
import "controllers"
import { Turbo } from "@hotwired/turbo-rails"

Turbo.setConfirmMethod((message) => {
  return new Promise((resolve) => {
    const overlay = document.createElement("div")
    overlay.className = "confirm-modal-overlay"
    overlay.innerHTML = `
      <div class="confirm-modal-dialog">
        <p style="margin:0 0 1.5rem;color:oklch(92% 0.003 254);font-size:0.95rem;line-height:1.5;">${message}</p>
        <div style="display:flex;justify-content:flex-end;gap:0.75rem;">
          <button class="confirm-modal-btn confirm-modal-cancel">Cancel</button>
          <button class="confirm-modal-btn confirm-modal-ok">Confirm</button>
        </div>
      </div>
    `

    const respond = (value) => {
      overlay.remove()
      resolve(value)
    }

    overlay.querySelector(".confirm-modal-cancel").addEventListener("click", () => respond(false))
    overlay.querySelector(".confirm-modal-ok").addEventListener("click", () => respond(true))
    overlay.addEventListener("click", (e) => { if (e.target === overlay) respond(false) })
    document.addEventListener("keydown", function handler(e) {
      if (e.key === "Escape") { document.removeEventListener("keydown", handler); respond(false) }
    })

    document.body.appendChild(overlay)
    overlay.querySelector(".confirm-modal-cancel").focus()
  })
})
