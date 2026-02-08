class TestPlansController < ApplicationController
  include Pagy::Method

  before_action :set_test_plan, only: [:show, :edit, :update, :destroy, :report]
  before_action :authorize_owner_or_admin, only: [:edit, :update, :destroy]

  def index
    @test_plans = TestPlan.includes(:test_scenarios, :user, :tags).order(created_at: :desc)

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

    @search = params[:search]
    @test_plans = @test_plans.search(@search) if @search.present?

    @filters_active = params[:status].present? || params[:date_from].present? || params[:date_until].present? || @search.present?

    @pagy, @test_plans = pagy(@test_plans)
  end

  def show
    @test_scenarios = @test_plan.test_scenarios.to_a
    @new_scenario = @test_plan.test_scenarios.build
  end

  def new
    @test_plan = TestPlan.new
  end

  def create
    @test_plan = TestPlan.new(test_plan_params)
    @test_plan.user = Current.user

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
    respond_to do |format|
      format.html { render 'report', layout: false }
      format.pdf do
        require "base64"
        logo_b64 = Base64.strict_encode64(File.read(Rails.root.join("app/assets/images/testy-logo.png")))
        now = Time.zone.now.strftime("%d/%m/%Y às %H:%M")

        footer_html = <<~HTML
          <div style="margin:-1px 0 0 0;padding:0;width:100%;height:150%;background:#f5f3ef;display:flex;align-items:flex-end;justify-content:center;font-family:'Helvetica Neue',Arial,sans-serif;">
            <div style="text-align:center;padding-bottom:12px;border-top:3px solid #e8e4dd;margin:0 40px;flex:1;padding-top:8px;">
              <img src="data:image/png;base64,#{logo_b64}" width="20" height="20" style="display:block;margin:0 auto 3px;" />
              <div style="font-size:9px;color:#999;">Test Management Made Simple</div>
              <div style="font-size:8px;color:#bbb;">#{now}</div>
            </div>
          </div>
        HTML

        render ferrum_pdf: {
          paper_width: 8.27,
          paper_height: 11.69,
          margin_bottom: 0.55,
          display_header_footer: true,
          header_template: '<div style="width:100%;height:100%;background:#f5f3ef;"></div>',
          footer_template: footer_html
        },
        template: "test_plans/report_pdf",
        formats: [:html],
        layout: false,
        disposition: :inline,
        filename: "plano_teste_#{@test_plan.id}.pdf"
      end
    end
  end
  private

  def set_test_plan
    @test_plan = TestPlan.find(params[:id])
  end

  def test_plan_params
    params.require(:test_plan).permit(:name, :qa_name, :tag_list)
  end

  def authorize_owner_or_admin
    authorize_plan_owner_or_admin(@test_plan)
  end
end