class TestPlansController < ApplicationController
  before_action :set_test_plan, only: [:show, :edit, :update, :destroy, :report]

  def index
    @test_plans = TestPlan.includes(:test_scenarios).order(created_at: :desc)

    if params[:status].present?
      @test_plans = case params[:status]
      when "aprovado" then @test_plans.aprovado
      when "reprovado" then @test_plans.reprovado
      when "em_andamento" then @test_plans.em_andamento
      when "nao_iniciado" then @test_plans.nao_iniciado
      else @test_plans
      end
    end

    @test_plans = @test_plans.created_from(params[:date_from]) if params[:date_from].present?
    @test_plans = @test_plans.created_until(params[:date_until]) if params[:date_until].present?

    @filters_active = params[:status].present? || params[:date_from].present? || params[:date_until].present?
  end

  def show
    @test_scenarios = @test_plan.test_scenarios.order(created_at: :asc)
    @new_scenario = @test_plan.test_scenarios.build
  end

  def new
    @test_plan = TestPlan.new
  end

  def create
    @test_plan = TestPlan.new(test_plan_params)
    
    if @test_plan.save
      redirect_to @test_plan, notice: 'Plano de teste criado com sucesso!'
    else
      render :new, status: :unprocessable_entity
    end
  end

  def edit
  end

  def update
    if @test_plan.update(test_plan_params)
      redirect_to @test_plan, notice: 'Plano de teste atualizado!'
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    @test_plan.destroy
    redirect_to test_plans_path, notice: 'Plano de teste removido!'
  end

  def report
    @base_url = request.base_url

    respond_to do |format|
      format.html { render 'report' }
      format.pdf do
        render pdf: "plano_teste_#{@test_plan.id}",
               page_size: 'A4',
               margin: { top: 20, bottom: 20, left: 20, right: 20 }
      end
    end
  end
  private

  def set_test_plan
    @test_plan = TestPlan.find(params[:id])
  end

  def test_plan_params
    params.require(:test_plan).permit(:name, :qa_name)
  end
end