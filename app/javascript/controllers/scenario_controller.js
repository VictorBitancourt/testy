import { Controller } from "@hotwired/stimulus"
import { t } from "i18n_helper"

const BUG_ICON = '<svg xmlns="http://www.w3.org/2000/svg" class="h-4 w-4 inline" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.5" stroke-linecap="round" stroke-linejoin="round"><path d="M8 2l1.5 3M16 2l-1.5 3"/><path d="M9 5h6a4 4 0 014 4v1a2 2 0 01-2 2H7a2 2 0 01-2-2V9a4 4 0 014-4z"/><path d="M7 12v4a5 5 0 0010 0v-4"/><path d="M5 10H3m18 0h-2"/><path d="M5 14H3m18 0h-2"/><path d="M12 12v9"/></svg>'

export default class extends Controller {
  static targets = ["container", "stamp"]
  static values = { testPlanId: Number }

  connect() {
    this.checkAllApproved()
  }

  async updateStatus(event) {
    const button = event.currentTarget
    const scenarioId = button.dataset.scenarioId
    const status = button.dataset.status
    const card = document.querySelector(`[data-scenario-id="${scenarioId}"]`)

    // Prevent approving a scenario with an associated bug
    if (status === 'approved') {
      const bugLink = card.querySelector('.bug-association-container a')
      if (bugLink) {
        this._showAlert(t('scenario.cannot_approve_with_bug'))
        return
      }
    }

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
        card.dataset.scenarioStatus = status

        // Find the buttons div
        const buttonsDiv = button.parentElement

        // Remove all status buttons/badges
        buttonsDiv.querySelectorAll('button[data-status], button[data-action*="resetStatus"]').forEach(btn => btn.remove())

        // Add clickable status badge
        const badge = document.createElement('button')
        badge.dataset.action = 'click->scenario#resetStatus'
        badge.dataset.scenarioId = scenarioId
        badge.className = status === 'approved'
          ? 'bg-fz-green-dark hover:bg-fz-green-darker text-white px-6 py-2 rounded-lg font-semibold transition cursor-pointer'
          : 'bg-fz-red-dark hover:bg-fz-red-darker text-white px-6 py-2 rounded-lg font-semibold transition cursor-pointer'
        badge.textContent = status === 'approved' ? `\u2713 ${t('scenario.approved')}` : `\u2717 ${t('scenario.failed')}`

        // Insert badge before the edit/delete buttons
        buttonsDiv.insertBefore(badge, buttonsDiv.firstChild)

        // Check if all are approved to show the stamp
        this.checkAllApproved()

        // Show bug association button when failed
        if (status === 'failed') {
          const container = card.querySelector('.bug-association-container')
          if (container && !container.querySelector('a')) {
            container.innerHTML = `<button type="button" data-action="click->scenario#showBugSearch" data-scenario-id="${scenarioId}" class="text-sm text-fz-red-light hover:text-fz-red-medium font-semibold cursor-pointer">${BUG_ICON} ${t('scenario.associate_bug')}</button>`
          }
        }

        // Hide bug association button when approved
        if (status === 'approved') {
          const container = card.querySelector('.bug-association-container')
          if (container) {
            container.innerHTML = ''
          }
        }
      } else if (data.errors) {
        alert(data.errors.join(', '))
      }
    } catch (error) {
      console.error('Error updating status:', error)
      alert(t('scenario.error_status'))
    }
  }

  resetStatus(event) {
    const button = event.currentTarget
    const scenarioId = button.dataset.scenarioId
    const card = document.querySelector(`[data-scenario-id="${scenarioId}"]`)
    const buttonsDiv = button.parentElement

    // Remove the badge button
    button.remove()

    // Add approve/fail buttons
    const approveBtn = document.createElement('button')
    approveBtn.dataset.action = 'click->scenario#updateStatus'
    approveBtn.dataset.status = 'approved'
    approveBtn.dataset.scenarioId = scenarioId
    approveBtn.className = 'bg-fz-green-dark hover:bg-fz-green-darker text-white px-4 py-2 rounded-lg font-semibold transition cursor-pointer'
    approveBtn.textContent = `\u2713 ${t('scenario.approve')}`

    const failBtn = document.createElement('button')
    failBtn.dataset.action = 'click->scenario#updateStatus'
    failBtn.dataset.status = 'failed'
    failBtn.dataset.scenarioId = scenarioId
    failBtn.className = 'bg-fz-red-dark hover:bg-fz-red-darker text-white px-4 py-2 rounded-lg font-semibold transition cursor-pointer'
    failBtn.textContent = `\u2717 ${t('scenario.fail')}`

    buttonsDiv.insertBefore(failBtn, buttonsDiv.firstChild)
    buttonsDiv.insertBefore(approveBtn, buttonsDiv.firstChild)
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
    return this.testPlanIdValue
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

    // Show file upload + save/cancel buttons
    let actionsDiv = card.querySelector('.inline-edit-actions')
    if (!actionsDiv) {
      actionsDiv = document.createElement('div')
      actionsDiv.className = 'inline-edit-actions mt-3 space-y-3'

      const fileId = `edit-evidence-${scenarioId}`
      actionsDiv.innerHTML = `
        <div>
          <label class="cursor-pointer inline-flex items-center gap-1.5 bg-fz-blue-dark hover:bg-fz-blue-darker text-white font-semibold px-4 py-2 rounded-lg transition text-sm">
            <svg xmlns="http://www.w3.org/2000/svg" class="h-4 w-4" fill="none" viewBox="0 0 24 24" stroke="currentColor" stroke-width="2"><path stroke-linecap="round" stroke-linejoin="round" d="M15.172 7l-6.586 6.586a2 2 0 102.828 2.828l6.414-6.586a4 4 0 00-5.656-5.656l-6.415 6.585a6 6 0 108.486 8.486L20.5 13" /></svg>
            ${t('scenario.upload_evidence')}
            <input type="file" id="${fileId}" multiple accept="image/*,.pdf" class="hidden" />
          </label>
          <span class="text-sm text-ink-medium ml-2" data-file-count>${t('scenario.no_file_selected')}</span>
        </div>
        <div class="flex gap-2">
          <button type="button" data-action="click->scenario#saveEdit" data-scenario-id="${scenarioId}" class="bg-fz-green-dark hover:bg-fz-green-darker text-white px-4 py-2 rounded-lg font-semibold transition cursor-pointer">${t('scenario.save')}</button>
          <button type="button" data-action="click->scenario#cancelEdit" data-scenario-id="${scenarioId}" class="bg-surface-raised hover:bg-ink-lightest text-ink-dark px-4 py-2 rounded-lg font-semibold transition cursor-pointer">${t('scenario.cancel')}</button>
        </div>
      `

      const fileInput = actionsDiv.querySelector(`#${fileId}`)
      const fileCount = actionsDiv.querySelector('[data-file-count]')
      fileInput.addEventListener('change', () => {
        const count = fileInput.files.length
        fileCount.textContent = count === 0 ? t('scenario.no_file_selected') :
                                count === 1 ? t('scenario.one_file_selected') :
                                t('scenario.files_selected', { count })
      })

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
    const fileInput = card.querySelector('.inline-edit-actions input[type="file"]')

    const formData = new FormData()
    formData.append('test_scenario[given]', given)
    formData.append('test_scenario[when_step]', whenStep)
    formData.append('test_scenario[then_step]', thenStep)

    if (fileInput && fileInput.files.length > 0) {
      for (const file of fileInput.files) {
        formData.append('test_scenario[evidence_files][]', file)
      }
    }

    try {
      const response = await fetch(`/test_plans/${this.getTestPlanId()}/test_scenarios/${scenarioId}`, {
        method: 'PATCH',
        headers: {
          'Accept': 'application/json',
          'X-CSRF-Token': this.getCSRFToken()
        },
        body: formData
      })

      const data = await response.json()

      if (data.success) {
        // Reload if files were attached so evidence renders server-side
        if (fileInput && fileInput.files.length > 0) {
          window.location.reload()
          return
        }

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
        alert(t('scenario.error_saving', { errors: (data.errors || []).join(', ') }))
      }
    } catch (error) {
      console.error('Error saving scenario:', error)
      alert(t('scenario.error_saving_generic'))
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
    const badge = buttonsDiv.querySelector('button[data-action*="resetStatus"]')
    if (badge) badge.remove()

    // Only add buttons if there aren't already approve/fail buttons
    if (!buttonsDiv.querySelector('[data-status]')) {
      const approveBtn = document.createElement('button')
      approveBtn.dataset.action = 'click->scenario#updateStatus'
      approveBtn.dataset.status = 'approved'
      approveBtn.dataset.scenarioId = scenarioId
      approveBtn.className = 'bg-fz-green-dark hover:bg-fz-green-darker text-white px-4 py-2 rounded-lg font-semibold transition cursor-pointer'
      approveBtn.textContent = `\u2713 ${t('scenario.approve')}`

      const failBtn = document.createElement('button')
      failBtn.dataset.action = 'click->scenario#updateStatus'
      failBtn.dataset.status = 'failed'
      failBtn.dataset.scenarioId = scenarioId
      failBtn.className = 'bg-fz-red-dark hover:bg-fz-red-darker text-white px-4 py-2 rounded-lg font-semibold transition cursor-pointer'
      failBtn.textContent = `\u2717 ${t('scenario.fail')}`

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

  showBugSearch(event) {
    const scenarioId = event.currentTarget.dataset.scenarioId
    const container = event.currentTarget.closest('.bug-association-container')

    container.innerHTML = `
      <div class="flex items-center gap-2 relative">
        <span>${BUG_ICON}</span>
        <input type="text" placeholder="${t('scenario.search_bug')}" class="bg-surface-raised border border-ink-lighter rounded-lg px-3 py-1.5 text-sm text-ink-darkest focus:ring-2 focus:ring-fz-blue-light focus:outline-none w-64" data-bug-search-input data-scenario-id="${scenarioId}" />
        <div class="hidden absolute top-full left-6 z-10 w-64 mt-1 bg-surface border border-ink-lighter rounded-lg shadow-lg max-h-48 overflow-y-auto dark-scrollbar" data-bug-search-results></div>
        <button type="button" class="text-ink-medium hover:text-fz-red-light text-xs cursor-pointer" data-action="click->scenario#cancelBugSearch" data-scenario-id="${scenarioId}">&#10005;</button>
      </div>
    `

    const input = container.querySelector('[data-bug-search-input]')
    input.focus()

    // Load all open bugs immediately
    this._fetchBugs('', container, scenarioId)

    let timeout = null
    input.addEventListener('input', () => {
      clearTimeout(timeout)
      const q = input.value.trim()
      timeout = setTimeout(() => this._fetchBugs(q, container, scenarioId), 200)
    })
  }

  async _fetchBugs(query, container, scenarioId) {
    try {
      const url = query ? `/bugs.json?q=${encodeURIComponent(query)}` : '/bugs.json?status=open'
      const response = await fetch(url)
      const bugs = await response.json()
      const results = container.querySelector('[data-bug-search-results]')

      if (bugs.length === 0) {
        results.classList.add('hidden')
        return
      }

      results.innerHTML = ''
      bugs.forEach(bug => {
        const btn = document.createElement('button')
        btn.type = 'button'
        btn.className = 'block w-full text-left px-3 py-2 text-sm text-ink-darkest hover:bg-surface-raised transition'
        btn.textContent = bug.display_name
        btn.addEventListener('click', () => this._associateBug(scenarioId, bug, container))
        results.appendChild(btn)
      })
      results.classList.remove('hidden')
    } catch (error) {
      console.error('Error fetching bugs:', error)
    }
  }

  async _associateBug(scenarioId, bug, container) {
    try {
      const formData = new FormData()
      formData.append('test_scenario[bug_id]', bug.id)

      const response = await fetch(`/test_plans/${this.getTestPlanId()}/test_scenarios/${scenarioId}`, {
        method: 'PATCH',
        headers: {
          'Accept': 'application/json',
          'X-CSRF-Token': this.getCSRFToken()
        },
        body: formData
      })

      const data = await response.json()
      if (data.success) {
        container.innerHTML = `
          <div class="flex items-center gap-2 text-sm">
            <span>${BUG_ICON}</span>
            <a href="/bugs/${bug.id}" class="text-fz-red-light hover:text-fz-red-medium font-semibold">${bug.display_name}</a>
            <button type="button" data-action="click->scenario#removeBug" data-scenario-id="${scenarioId}" class="text-ink-medium hover:text-fz-red-light text-xs ml-1 cursor-pointer">&#10005;</button>
          </div>
        `
      }
    } catch (error) {
      console.error('Error associating bug:', error)
    }
  }

  async removeBug(event) {
    const scenarioId = event.currentTarget.dataset.scenarioId
    const container = event.currentTarget.closest('.bug-association-container')

    try {
      const formData = new FormData()
      formData.append('test_scenario[bug_id]', '')

      const response = await fetch(`/test_plans/${this.getTestPlanId()}/test_scenarios/${scenarioId}`, {
        method: 'PATCH',
        headers: {
          'Accept': 'application/json',
          'X-CSRF-Token': this.getCSRFToken()
        },
        body: formData
      })

      const data = await response.json()
      if (data.success) {
        const card = document.querySelector(`[data-scenario-id="${scenarioId}"]`)
        if (card && card.dataset.scenarioStatus === 'failed') {
          container.innerHTML = `<button type="button" data-action="click->scenario#showBugSearch" data-scenario-id="${scenarioId}" class="text-sm text-fz-red-light hover:text-fz-red-medium font-semibold cursor-pointer">${BUG_ICON} ${t('scenario.associate_bug')}</button>`
        } else {
          container.innerHTML = ''
        }
      }
    } catch (error) {
      console.error('Error removing bug:', error)
    }
  }

  cancelBugSearch(event) {
    const scenarioId = event.currentTarget.dataset.scenarioId
    const container = event.currentTarget.closest('.bug-association-container')
    container.innerHTML = `<button type="button" data-action="click->scenario#showBugSearch" data-scenario-id="${scenarioId}" class="text-sm text-fz-red-light hover:text-fz-red-medium font-semibold cursor-pointer">${BUG_ICON} ${t('scenario.associate_bug')}</button>`
  }

  _showAlert(message) {
    const overlay = document.createElement('div')
    overlay.className = 'confirm-modal-overlay'

    const dialog = document.createElement('div')
    dialog.className = 'confirm-modal-dialog'

    const p = document.createElement('p')
    p.style.cssText = 'margin:0 0 1.5rem;color:oklch(92% 0.003 254);font-size:0.95rem;line-height:1.5;'
    p.textContent = message

    const actions = document.createElement('div')
    actions.style.cssText = 'display:flex;justify-content:flex-end;'

    const okBtn = document.createElement('button')
    okBtn.className = 'confirm-modal-btn confirm-modal-ok'
    okBtn.textContent = 'OK'

    const close = () => overlay.remove()
    okBtn.addEventListener('click', close)
    overlay.addEventListener('click', (e) => { if (e.target === overlay) close() })
    document.addEventListener('keydown', function handler(e) {
      if (e.key === 'Escape' || e.key === 'Enter') { document.removeEventListener('keydown', handler); close() }
    })

    actions.appendChild(okBtn)
    dialog.appendChild(p)
    dialog.appendChild(actions)
    overlay.appendChild(dialog)
    document.body.appendChild(overlay)
    okBtn.focus()
  }

  getCSRFToken() {
    return document.querySelector('meta[name="csrf-token"]').content
  }
}
