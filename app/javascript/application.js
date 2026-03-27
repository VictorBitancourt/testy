// Configure your import map in config/importmap.rb. Read more: https://github.com/rails/importmap-rails
import "@hotwired/turbo-rails"
import "controllers"
import "i18n_helper"
import { Turbo } from "@hotwired/turbo-rails"
import { t } from "i18n_helper"

Turbo.setConfirmMethod((message) => {
  return new Promise((resolve) => {
    const dialog = document.createElement("dialog")
    dialog.className = "confirm-dialog"

    const p = document.createElement("p")
    p.className = "confirm-dialog__text"
    p.textContent = message

    const actions = document.createElement("div")
    actions.className = "confirm-dialog__actions"

    const cancelBtn = document.createElement("button")
    cancelBtn.className = "confirm-dialog__btn confirm-dialog__cancel"
    cancelBtn.textContent = t('confirm_modal.cancel')

    const okBtn = document.createElement("button")
    okBtn.className = "confirm-dialog__btn confirm-dialog__ok"
    okBtn.textContent = t('confirm_modal.confirm')

    actions.appendChild(cancelBtn)
    actions.appendChild(okBtn)
    dialog.appendChild(p)
    dialog.appendChild(actions)

    const respond = (value) => {
      dialog.close()
      dialog.remove()
      resolve(value)
    }

    cancelBtn.addEventListener("click", () => respond(false))
    okBtn.addEventListener("click", () => respond(true))
    dialog.addEventListener("cancel", () => respond(false))

    document.body.appendChild(dialog)
    dialog.showModal()
    cancelBtn.focus()
  })
})
