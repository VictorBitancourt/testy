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
      const response = await fetch(`/test_plans/${this.getTestPlanId()}/test_scenarios/${scenarioId}/update_status`, {
        method: 'PATCH',
        headers: {
          'Content-Type': 'application/json',
          'X-CSRF-Token': this.getCSRFToken()
        },
        body: JSON.stringify({ status: status })
      })
      
      const data = await response.json()
      
      if (data.success) {
        // Atualizar o card inteiro
        const card = document.querySelector(`[data-scenario-id="${scenarioId}"]`)
        card.dataset.scenarioStatus = status
        
        // Encontrar a div dos botões
        const buttonsDiv = button.parentElement
        
        // Remover todos os botões
        buttonsDiv.querySelectorAll('button').forEach(btn => {
          if (btn.dataset.scenarioId) {
            btn.remove()
          }
        })
        
        // Adicionar o badge de status
        const badge = document.createElement('div')
        badge.className = status === 'approved' 
          ? 'bg-green-500 text-white px-6 py-2 rounded-lg font-semibold' 
          : 'bg-red-500 text-white px-6 py-2 rounded-lg font-semibold'
        badge.textContent = status === 'approved' ? '✓ Aprovado' : '✗ Reprovado'
        
        // Inserir o badge antes do botão de deletar
        buttonsDiv.insertBefore(badge, buttonsDiv.firstChild)
        
        // Verificar se todos estão aprovados para mostrar o carimbo
        this.checkAllApproved()
      }
    } catch (error) {
      console.error('Erro ao atualizar status:', error)
      alert('Erro ao atualizar o status do cenário')
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

  getCSRFToken() {
    return document.querySelector('meta[name="csrf-token"]').content
  }
}