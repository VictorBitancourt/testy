// Configure your import map in config/importmap.rb. Read more: https://github.com/rails/importmap-rails
import "@hotwired/turbo-rails"
import "controllers"
import "i18n_helper"
import { Turbo } from "@hotwired/turbo-rails"
import { t } from "i18n_helper"

Turbo.setConfirmMethod((message) => {
  return new Promise((resolve) => {
    const overlay = document.createElement("div")
    overlay.className = "confirm-modal-overlay"

    const dialog = document.createElement("div")
    dialog.className = "confirm-modal-dialog"

    const p = document.createElement("p")
    p.style.cssText = "margin:0 0 1.5rem;color:oklch(92% 0.003 254);font-size:0.95rem;line-height:1.5;"
    p.textContent = message

    const actions = document.createElement("div")
    actions.style.cssText = "display:flex;justify-content:flex-end;gap:0.75rem;"

    const cancelBtn = document.createElement("button")
    cancelBtn.className = "confirm-modal-btn confirm-modal-cancel"
    cancelBtn.textContent = t('confirm_modal.cancel')

    const okBtn = document.createElement("button")
    okBtn.className = "confirm-modal-btn confirm-modal-ok"
    okBtn.textContent = t('confirm_modal.confirm')

    actions.appendChild(cancelBtn)
    actions.appendChild(okBtn)
    dialog.appendChild(p)
    dialog.appendChild(actions)
    overlay.appendChild(dialog)

    const respond = (value) => {
      overlay.remove()
      resolve(value)
    }

    cancelBtn.addEventListener("click", () => respond(false))
    okBtn.addEventListener("click", () => respond(true))
    overlay.addEventListener("click", (e) => { if (e.target === overlay) respond(false) })
    document.addEventListener("keydown", function handler(e) {
      if (e.key === "Escape") { document.removeEventListener("keydown", handler); respond(false) }
    })

    document.body.appendChild(overlay)
    cancelBtn.focus()
  })
})
