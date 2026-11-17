import { Controller } from "@hotwired/stimulus"
import { t } from "i18n_helper"

// Adds images from the clipboard to a file input, either via Ctrl+V or a button.
// Pastes inside the scope element go to this controller; pastes with nothing
// focused go to the most recently connected one (e.g. an open inline edit).
const active = []

export default class extends Controller {
  static targets = ["input", "button", "status"]
  static values = { scope: String }

  connect() {
    this.handlePaste = this.handlePaste.bind(this)
    document.addEventListener("paste", this.handlePaste)
    active.push(this)

    if (this.hasButtonTarget && !navigator.clipboard?.read) {
      this.buttonTarget.classList.add("hidden")
    }
  }

  disconnect() {
    document.removeEventListener("paste", this.handlePaste)
    active.splice(active.indexOf(this), 1)
  }

  handlePaste(event) {
    if (!this.ownsPaste(event.target)) return

    const images = Array.from(event.clipboardData?.files || []).filter(f => f.type.startsWith("image/"))
    if (images.length === 0) return

    // Copying from a web page may carry text too; let it paste into text fields
    const isTextField = ["INPUT", "TEXTAREA"].includes(event.target.tagName) || event.target.isContentEditable
    if (isTextField && event.clipboardData.getData("text/plain")) return

    event.preventDefault()
    this.addFiles(images)
  }

  async pasteFromClipboard() {
    try {
      const items = await navigator.clipboard.read()
      const images = []
      for (const item of items) {
        const type = item.types.find(t => t.startsWith("image/"))
        if (type) images.push(new File([await item.getType(type)], "image", { type }))
      }

      if (images.length === 0) {
        this.showStatus(t("clipboard_paste.no_image"))
        return
      }
      this.addFiles(images)
    } catch (e) {
      console.error("Clipboard read failed:", e)
      this.showStatus(t("clipboard_paste.denied"))
    }
  }

  ownsPaste(target) {
    const scope = this.scopeValue ? this.element.closest(this.scopeValue) : this.element
    if (scope?.contains(target)) return true

    const nothingFocused = target === document.body || target === document.documentElement
    return nothingFocused && active[active.length - 1] === this
  }

  addFiles(images) {
    const transfer = new DataTransfer()
    for (const file of this.inputTarget.files) transfer.items.add(file)

    const existing = transfer.files.length
    const stamp = new Date().toISOString().replace(/[-:]/g, "").replace("T", "-").slice(0, 15)
    images.forEach((image, i) => {
      const ext = image.type.split("/")[1]?.replace("jpeg", "jpg") || "png"
      const suffix = existing + i + 1
      transfer.items.add(new File([image], `print-${stamp}-${suffix}.${ext}`, { type: image.type }))
    })

    this.inputTarget.files = transfer.files
    this.inputTarget.dispatchEvent(new Event("change", { bubbles: true }))
  }

  showStatus(message) {
    if (this.hasStatusTarget) this.statusTarget.textContent = message
  }
}
