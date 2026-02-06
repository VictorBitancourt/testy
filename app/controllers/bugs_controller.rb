class BugsController < ApplicationController
  include Pagy::Method

  before_action :set_bug, only: [ :show, :edit, :update, :destroy ]
  before_action :authorize_owner_or_admin, only: [ :edit, :update, :destroy ]

  def index
    @bugs = Bug.includes(:user).order(created_at: :desc)

    @bugs = @bugs.where(status: params[:status]) if params[:status].present?
    @bugs = @bugs.by_feature(params[:feature_tag])
    @bugs = @bugs.by_cause(params[:cause_tag])
    @bugs = @bugs.created_from(params[:date_from]) if params[:date_from].present?
    @bugs = @bugs.created_until(params[:date_until]) if params[:date_until].present?

    @search = params[:search] || params[:q]
    @bugs = @bugs.search(@search) if @search.present?

    @filters_active = params[:status].present? || params[:feature_tag].present? || params[:cause_tag].present? || params[:date_from].present? || params[:date_until].present? || @search.present?

    respond_to do |format|
      format.html do
        @pagy, @bugs = pagy(@bugs)
      end
      format.json { render json: @bugs.limit(20).map { |b| { id: b.id, display_name: b.display_name } } }
    end
  end

  def show
  end

  def new
    @bug = Bug.new
  end

  def create
    @bug = Bug.new(bug_params)
    @bug.user = Current.user

    if @bug.save
      redirect_to @bug, notice: t("controllers.bugs.created")
    else
      render :new, status: :unprocessable_entity
    end
  end

  def edit
  end

  def update
    if @bug.update(bug_params)
      redirect_to @bug, notice: t("controllers.bugs.updated")
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    @bug.destroy
    redirect_to bugs_path, notice: t("controllers.bugs.removed")
  end

  def tag_suggestions
    field = params[:field]&.to_sym
    return head(:bad_request) unless field.in?([ :feature_tag, :cause_tag ])

    query = params[:q].to_s.strip
    tags = Bug.where.not(field => [ nil, "" ])
              .where("#{field} LIKE ?", "%#{Bug.sanitize_sql_like(query)}%")
              .distinct.pluck(field)
              .first(10)

    render json: tags
  end

  private
    def set_bug
      @bug = Bug.find(params[:id])
    end

    def authorize_owner_or_admin
      authorize_record_owner_or_admin(@bug)
    end

    def bug_params
      params.require(:bug).permit(:title, :description, :steps_to_reproduce, :obtained_result, :expected_result, :feature_tag, :cause_tag, :status, evidence_files: [])
    end
end
