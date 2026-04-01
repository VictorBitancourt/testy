import { Controller } from "@hotwired/stimulus"
import { t } from "i18n_helper"

const BUG_ICON = '<span class="icon icon--bug icon--sm" aria-hidden="true"></span>'

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
          ? 'scenario-btn scenario-btn--approved'
          : 'scenario-btn scenario-btn--failed'
        badge.textContent = status === 'approved' ? `\u2713 ${t('scenario.approved')}` : `\u2717 ${t('scenario.failed')}`

        // Insert badge before the edit/delete buttons
        buttonsDiv.insertBefore(badge, buttonsDiv.firstChild)

        // Check if all are approved to show the stamp
        this.checkAllApproved()

        // Show bug association button when failed
        if (status === 'failed') {
          const container = card.querySelector('.bug-association-container')
          if (container && !container.querySelector('a')) {
            container.innerHTML = `<button type="button" data-action="click->scenario#showBugSearch" data-scenario-id="${scenarioId}" class="bug-associate-btn">${BUG_ICON} ${t('scenario.associate_bug')}</button>`
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
    approveBtn.className = 'scenario-btn scenario-btn--approved'
    approveBtn.textContent = `\u2713 ${t('scenario.approve')}`

    const failBtn = document.createElement('button')
    failBtn.dataset.action = 'click->scenario#updateStatus'
    failBtn.dataset.status = 'failed'
    failBtn.dataset.scenarioId = scenarioId
    failBtn.className = 'scenario-btn scenario-btn--failed'
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
      textarea.className = 'input input--textarea'
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
      actionsDiv.className = 'inline-edit-actions mt-3 stack--sm'

      const fileId = `edit-evidence-${scenarioId}`
      actionsDiv.innerHTML = `
        <div>
          <label class="btn btn--primary btn--sm" style="cursor:pointer;">
<span class="icon icon--paperclip icon--sm" aria-hidden="true"></span>
            ${t('scenario.upload_evidence')}
            <input type="file" id="${fileId}" multiple accept="image/*,.pdf" class="hidden" />
          </label>
          <span class="text-sm txt-ink-medium" style="margin-left:var(--space-2);" data-file-count>${t('scenario.no_file_selected')}</span>
        </div>
        <div class="flex gap-2">
          <button type="button" data-action="click->scenario#saveEdit" data-scenario-id="${scenarioId}" class="scenario-btn scenario-btn--approved">${t('scenario.save')}</button>
          <button type="button" data-action="click->scenario#cancelEdit" data-scenario-id="${scenarioId}" class="scenario-btn scenario-btn--edit">${t('scenario.cancel')}</button>
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

      const gridDiv = card.querySelector('.scenario-card__steps')
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
      p.className = 'step-box__text step-text'
      p.textContent = value
      textarea.replaceWith(p)
    })
  }

  _restoreStatusButtons(card) {
    const scenarioId = card.dataset.scenarioId
    const buttonsDiv = card.querySelector('.scenario-card__actions')
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
      approveBtn.className = 'scenario-btn scenario-btn--approved'
      approveBtn.textContent = `\u2713 ${t('scenario.approve')}`

      const failBtn = document.createElement('button')
      failBtn.dataset.action = 'click->scenario#updateStatus'
      failBtn.dataset.status = 'failed'
      failBtn.dataset.scenarioId = scenarioId
      failBtn.className = 'scenario-btn scenario-btn--failed'
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
      p.className = 'step-box__text step-text'
      p.textContent = textarea.dataset.originalText || textarea.value
      textarea.replaceWith(p)
    })
  }

  showBugSearch(event) {
    const scenarioId = event.currentTarget.dataset.scenarioId
    const container = event.currentTarget.closest('.bug-association-container')

    container.innerHTML = `
      <div class="bug-link relative">
        <span>${BUG_ICON}</span>
        <input type="text" placeholder="${t('scenario.search_bug')}" class="input input--sm input--search" data-bug-search-input data-scenario-id="${scenarioId}" />
        <div class="hidden suggestions" style="left:var(--space-6);" data-bug-search-results></div>
        <button type="button" class="bug-link__remove" data-action="click->scenario#cancelBugSearch" data-scenario-id="${scenarioId}">&#10005;</button>
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
        btn.className = 'suggestions__item'
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
          <div class="bug-link">
            <span>${BUG_ICON}</span>
            <a href="/bugs/${bug.id}" class="bug-link__name">${bug.display_name}</a>
            <button type="button" data-action="click->scenario#removeBug" data-scenario-id="${scenarioId}" class="bug-link__remove">&#10005;</button>
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
          container.innerHTML = `<button type="button" data-action="click->scenario#showBugSearch" data-scenario-id="${scenarioId}" class="bug-associate-btn">${BUG_ICON} ${t('scenario.associate_bug')}</button>`
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
    container.innerHTML = `<button type="button" data-action="click->scenario#showBugSearch" data-scenario-id="${scenarioId}" class="bug-associate-btn">${BUG_ICON} ${t('scenario.associate_bug')}</button>`
  }

  _showAlert(message) {
    const dialog = document.createElement('dialog')
    dialog.className = 'confirm-dialog'

    const p = document.createElement('p')
    p.className = 'confirm-dialog__text'
    p.textContent = message

    const actions = document.createElement('div')
    actions.className = 'confirm-dialog__actions'

    const okBtn = document.createElement('button')
    okBtn.className = 'confirm-dialog__btn confirm-dialog__ok'
    okBtn.textContent = 'OK'

    const close = () => { dialog.close(); dialog.remove() }
    okBtn.addEventListener('click', close)
    dialog.addEventListener('cancel', close)

    actions.appendChild(okBtn)
    dialog.appendChild(p)
    dialog.appendChild(actions)
    document.body.appendChild(dialog)
    dialog.showModal()
    okBtn.focus()
  }

  getCSRFToken() {
    return document.querySelector('meta[name="csrf-token"]').content
  }
}
