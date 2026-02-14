import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["container", "stamp"]

  connect() {
    this.checkAllApproved()
  }

  async updateStatus(event) {
    const button = event.currentTarget
    const scenarioId = button.dataset.scenarioId
    const status = button.dataset.status
    
    try {
      const response = await fetch(`/test_plans/${this.getTestPlanId()}/test_scenarios/${scenarioId}/status`, {
        method: 'PATCH',
        headers: {
          'Content-Type': 'application/json',
          'X-CSRF-Token': this.getCSRFToken()
        },
        body: JSON.stringify({ status: status })
      })
      
      const data = await response.json()
      
      if (data.success) {
        // Update the entire card
        const card = document.querySelector(`[data-scenario-id="${scenarioId}"]`)
        card.dataset.scenarioStatus = status
        
        // Find the buttons div
        const buttonsDiv = button.parentElement
        
        // Remove all buttons
        buttonsDiv.querySelectorAll('button').forEach(btn => {
          if (btn.dataset.scenarioId) {
            btn.remove()
          }
        })
        
        // Add status badge
        const badge = document.createElement('div')
        badge.className = status === 'approved' 
          ? 'bg-green-500 text-white px-6 py-2 rounded-lg font-semibold' 
          : 'bg-red-500 text-white px-6 py-2 rounded-lg font-semibold'
        badge.textContent = status === 'approved' ? '✓ Approved' : '✗ Failed'
        
        // Insert badge before the delete button
        buttonsDiv.insertBefore(badge, buttonsDiv.firstChild)
        
        // Check if all are approved to show the stamp
        this.checkAllApproved()
      }
    } catch (error) {
      console.error('Error updating status:', error)
      alert('Error updating the scenario status')
    }
  }

  checkAllApproved() {
    const scenarios = this.containerTarget.querySelectorAll('.scenario-card')
    const allApproved = Array.from(scenarios).every(card => 
      card.dataset.scenarioStatus === 'approved'
    )
    
    if (allApproved && scenarios.length > 0) {
      this.stampTarget.classList.remove('hidden')
    } else {
      this.stampTarget.classList.add('hidden')
    }
  }

  getTestPlanId() {
    return window.location.pathname.split('/')[2]
  }

  toggleEdit(event) {
    const card = event.currentTarget.closest('.scenario-card')
    if (!card || card.dataset.editing === 'true') return

    card.dataset.editing = 'true'
    card.draggable = false
    const scenarioId = card.dataset.scenarioId

    const steps = [
      { key: 'given', selector: '[data-step="given"]' },
      { key: 'when_step', selector: '[data-step="when"]' },
      { key: 'then_step', selector: '[data-step="then"]' }
    ]

    steps.forEach(({ key, selector }) => {
      const box = card.querySelector(selector)
      const textEl = box.querySelector('p.step-text')
      const originalText = textEl.textContent

      const textarea = document.createElement('textarea')
      textarea.className = 'w-full px-2 py-1 bg-surface-raised border border-ink-lighter rounded-lg text-ink-darkest focus:ring-2 focus:ring-fz-blue-light resize-y'
      textarea.rows = 3
      textarea.name = key
      textarea.value = originalText
      textarea.dataset.originalText = originalText
      textEl.replaceWith(textarea)
    })

    // Show save/cancel buttons
    let actionsDiv = card.querySelector('.inline-edit-actions')
    if (!actionsDiv) {
      actionsDiv = document.createElement('div')
      actionsDiv.className = 'inline-edit-actions flex gap-2 mt-3'
      actionsDiv.innerHTML = `
        <button type="button" data-action="click->scenario#saveEdit" data-scenario-id="${scenarioId}" class="bg-fz-green-dark hover:bg-fz-green-darker text-white px-4 py-2 rounded-lg font-semibold transition cursor-pointer">Save</button>
        <button type="button" data-action="click->scenario#cancelEdit" data-scenario-id="${scenarioId}" class="bg-surface-raised hover:bg-ink-lightest text-ink-dark px-4 py-2 rounded-lg font-semibold transition cursor-pointer">Cancel</button>
      `
      const gridDiv = card.querySelector('.grid')
      gridDiv.after(actionsDiv)
    }
  }

  async saveEdit(event) {
    const card = event.currentTarget.closest('.scenario-card')
    const scenarioId = card.dataset.scenarioId

    const given = card.querySelector('textarea[name="given"]').value
    const whenStep = card.querySelector('textarea[name="when_step"]').value
    const thenStep = card.querySelector('textarea[name="then_step"]').value

    try {
      const response = await fetch(`/test_plans/${this.getTestPlanId()}/test_scenarios/${scenarioId}`, {
        method: 'PATCH',
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          'X-CSRF-Token': this.getCSRFToken()
        },
        body: JSON.stringify({ test_scenario: { given: given, when_step: whenStep, then_step: thenStep } })
      })

      const data = await response.json()

      if (data.success) {
        this._restoreStepText(card, data.scenario)
        delete card.dataset.editing
        card.draggable = true
        card.querySelector('.inline-edit-actions')?.remove()

        // Status was reset to pending — update the card UI
        if (data.scenario.status === 'pending') {
          card.dataset.scenarioStatus = 'pending'
          this._restoreStatusButtons(card)
          this.checkAllApproved()
        }
      } else {
        alert('Error saving: ' + (data.errors || []).join(', '))
      }
    } catch (error) {
      console.error('Error saving scenario:', error)
      alert('Error saving the scenario')
    }
  }

  cancelEdit(event) {
    const card = event.currentTarget.closest('.scenario-card')
    this._restoreOriginalText(card)
    delete card.dataset.editing
    card.draggable = true
    card.querySelector('.inline-edit-actions')?.remove()
  }

  _restoreStepText(card, scenario) {
    const mapping = [
      { selector: '[data-step="given"]', value: scenario.given },
      { selector: '[data-step="when"]', value: scenario.when_step },
      { selector: '[data-step="then"]', value: scenario.then_step }
    ]

    mapping.forEach(({ selector, value }) => {
      const box = card.querySelector(selector)
      const textarea = box.querySelector('textarea')
      const p = document.createElement('p')
      p.className = 'text-ink-darker break-words step-text'
      p.textContent = value
      textarea.replaceWith(p)
    })
  }

  _restoreStatusButtons(card) {
    const scenarioId = card.dataset.scenarioId
    const buttonsDiv = card.querySelector('.flex.gap-2')
    if (!buttonsDiv) return

    // Remove existing badge (approved/failed)
    const badge = buttonsDiv.querySelector('div.bg-fz-green-dark, div.bg-fz-red-dark, div.bg-green-500, div.bg-red-500')
    if (badge) badge.remove()

    // Only add buttons if there aren't already approve/fail buttons
    if (!buttonsDiv.querySelector('[data-status]')) {
      const approveBtn = document.createElement('button')
      approveBtn.dataset.action = 'click->scenario#updateStatus'
      approveBtn.dataset.status = 'approved'
      approveBtn.dataset.scenarioId = scenarioId
      approveBtn.className = 'bg-fz-green-dark hover:bg-fz-green-darker text-white px-4 py-2 rounded-lg font-semibold transition'
      approveBtn.textContent = '✓ Approve'

      const failBtn = document.createElement('button')
      failBtn.dataset.action = 'click->scenario#updateStatus'
      failBtn.dataset.status = 'failed'
      failBtn.dataset.scenarioId = scenarioId
      failBtn.className = 'bg-fz-red-dark hover:bg-fz-red-darker text-white px-4 py-2 rounded-lg font-semibold transition'
      failBtn.textContent = '✗ Fail'

      buttonsDiv.insertBefore(failBtn, buttonsDiv.firstChild)
      buttonsDiv.insertBefore(approveBtn, buttonsDiv.firstChild)
    }
  }

  _restoreOriginalText(card) {
    const boxes = card.querySelectorAll('[data-step]')
    boxes.forEach(box => {
      const textarea = box.querySelector('textarea')
      if (!textarea) return
      const p = document.createElement('p')
      p.className = 'text-ink-darker break-words step-text'
      p.textContent = textarea.dataset.originalText || textarea.value
      textarea.replaceWith(p)
    })
  }

  getCSRFToken() {
    return document.querySelector('meta[name="csrf-token"]').content
  }
}