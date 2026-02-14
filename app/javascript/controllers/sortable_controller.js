import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["item"]
  static values = { url: String }

  connect() {
    this.draggedItem = null
  }

  // ── Desktop drag ──────────────────────────────────────

  dragStart(event) {
    this.draggedItem = event.currentTarget
    event.dataTransfer.effectAllowed = "move"
    event.dataTransfer.setData("text/plain", "")

    requestAnimationFrame(() => {
      this.draggedItem.style.opacity = "0.15"
      this.showDropZone()
    })
  }

  dragOver(event) {
    event.preventDefault()
    event.dataTransfer.dropEffect = "move"

    const target = this.findItem(event.target)
    if (!target || target === this.draggedItem) return

    const rect = target.getBoundingClientRect()
    const midY = rect.top + rect.height / 2

    // FLIP: record positions before DOM change
    const rects = this.capturePositions()

    if (event.clientY < midY) {
      this.element.insertBefore(this.draggedItem, target)
    } else {
      this.element.insertBefore(this.draggedItem, target.nextSibling)
    }

    // FLIP: animate from old positions to new
    this.animatePositions(rects)
  }

  dragEnd() {
    if (this.draggedItem) {
      this.draggedItem.style.opacity = ""
    }
    this.hideDropZone()
    this.draggedItem = null
    this.saveOrder()
  }

  // ── Touch drag ────────────────────────────────────────

  touchStart(event) {
    const handle = event.target.closest("[data-drag-handle]")
    if (!handle) return

    event.preventDefault()

    const item = event.currentTarget
    this.draggedItem = item
    const touch = event.touches[0]
    this.touchOffsetY = touch.clientY - item.getBoundingClientRect().top
    this.touchOffsetX = touch.clientX - item.getBoundingClientRect().left

    this.clone = item.cloneNode(true)
    Object.assign(this.clone.style, {
      position: "fixed",
      zIndex: "9999",
      width: `${item.offsetWidth}px`,
      pointerEvents: "none",
      opacity: "0.92",
      transform: "rotate(1deg) scale(1.03)",
      boxShadow: "0 25px 50px rgba(0,0,0,0.35)",
      transition: "none"
    })
    document.body.appendChild(this.clone)
    this.positionClone(touch.clientX, touch.clientY)

    item.style.opacity = "0.15"
    this.showDropZone()

    this.boundTouchMove = (e) => { e.preventDefault(); this.touchMove(e) }
    this.boundTouchEnd = () => this.touchEnd()
    document.addEventListener("touchmove", this.boundTouchMove, { passive: false })
    document.addEventListener("touchend", this.boundTouchEnd, { once: true })
  }

  touchMove(event) {
    const touch = event.touches[0]
    this.positionClone(touch.clientX, touch.clientY)

    const items = this.itemTargets.filter(i => i !== this.draggedItem)
    for (const item of items) {
      const rect = item.getBoundingClientRect()
      if (touch.clientY > rect.top && touch.clientY < rect.bottom) {
        const midY = rect.top + rect.height / 2
        const rects = this.capturePositions()

        if (touch.clientY < midY) {
          this.element.insertBefore(this.draggedItem, item)
        } else {
          this.element.insertBefore(this.draggedItem, item.nextSibling)
        }

        this.animatePositions(rects)
        break
      }
    }
  }

  touchEnd() {
    document.removeEventListener("touchmove", this.boundTouchMove)

    if (this.clone) { this.clone.remove(); this.clone = null }
    if (this.draggedItem) {
      this.draggedItem.style.opacity = ""
    }

    this.hideDropZone()
    this.draggedItem = null
    this.saveOrder()
  }

  positionClone(clientX, clientY) {
    if (!this.clone) return
    this.clone.style.top = `${clientY - this.touchOffsetY}px`
    this.clone.style.left = `${clientX - this.touchOffsetX}px`
  }

  // ── Drop zone (dashed border around entire container) ─

  showDropZone() {
    this.element.style.outline = "2px dashed var(--color-fz-violet-dark, #7c3aed)"
    this.element.style.outlineOffset = "12px"
    this.element.style.borderRadius = "16px"
  }

  hideDropZone() {
    this.element.style.outline = ""
    this.element.style.outlineOffset = ""
    this.element.style.borderRadius = ""
  }

  // ── FLIP animation for smooth reordering ──────────────

  capturePositions() {
    const rects = new Map()
    this.itemTargets.forEach(item => {
      rects.set(item, item.getBoundingClientRect())
    })
    return rects
  }

  animatePositions(oldRects) {
    this.itemTargets.forEach(item => {
      if (item === this.draggedItem) return

      const oldRect = oldRects.get(item)
      if (!oldRect) return

      const newRect = item.getBoundingClientRect()
      const deltaY = oldRect.top - newRect.top

      if (Math.abs(deltaY) < 1) return

      // Invert: place at old position
      item.style.transition = "none"
      item.style.transform = `translateY(${deltaY}px)`

      // Play: animate to new position
      requestAnimationFrame(() => {
        item.style.transition = "transform 0.3s cubic-bezier(0.2, 0, 0, 1)"
        item.style.transform = ""

        const cleanup = () => {
          item.style.transition = ""
          item.removeEventListener("transitionend", cleanup)
        }
        item.addEventListener("transitionend", cleanup, { once: true })
      })
    })
  }

  // ── Helpers ───────────────────────────────────────────

  findItem(element) {
    while (element && element !== this.element) {
      if (element.dataset && element.dataset.sortableTarget === "item") {
        return element
      }
      element = element.parentElement
    }
    return null
  }

  async saveOrder() {
    const ids = this.itemTargets.map(item => item.dataset.scenarioId)
    try {
      await fetch(this.urlValue, {
        method: "PATCH",
        headers: {
          "Content-Type": "application/json",
          "X-CSRF-Token": document.querySelector('meta[name="csrf-token"]').content
        },
        body: JSON.stringify({ scenario_ids: ids })
      })
    } catch (error) {
      console.error("Error saving order:", error)
    }
  }
}
