class TestScenariosController < ApplicationController
  before_action :set_test_plan
  before_action :set_test_scenario, only: [:update, :destroy, :update_status]
  before_action :authorize_owner_or_admin

  def create
    @test_scenario = @test_plan.test_scenarios.build(test_scenario_params)
    
    if @test_scenario.save
      redirect_to @test_plan, notice: 'Cenário adicionado!'
    else
      redirect_to @test_plan, alert: 'Erro ao adicionar cenário.'
    end
  end

  def update
    if @test_scenario.update(test_scenario_params)
      redirect_to @test_plan, notice: 'Cenário atualizado!'
    else
      redirect_to @test_plan, alert: 'Erro ao atualizar cenário.'
    end
  end

  def update_status
    if @test_scenario.update(status: params[:status])
      all_approved = @test_plan.all_scenarios_approved?
      render json: { success: true, all_approved: all_approved }
    else
      render json: { success: false }, status: :unprocessable_entity
    end
  end

  def reorder
    params[:scenario_ids].each_with_index do |id, index|
      @test_plan.test_scenarios.where(id: id).update_all(position: index)
    end
    head :ok
  end

  def destroy
    @test_scenario.destroy
    redirect_to @test_plan, notice: 'Cenário removido!'
  end

  private

  def set_test_plan
    @test_plan = TestPlan.find(params[:test_plan_id])
  end

  def set_test_scenario
    @test_scenario = @test_plan.test_scenarios.find(params[:id])
  end

  def test_scenario_params
    params.require(:test_scenario).permit(:title, :given, :when_step, :then_step, :status, evidence_files: [])
  end

  def authorize_owner_or_admin
    authorize_plan_owner_or_admin(@test_plan)
  end
end