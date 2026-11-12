class ProjectsController < ApplicationController
  before_action :set_project, only: [ :show, :edit, :update, :destroy ]
  before_action :authorize_owner_or_admin, only: [ :edit, :update, :destroy ]

  def index
    @projects = Project.order(:name)
    @plan_counts = TestPlan.group(:project_id).count
    @open_bug_counts = Bug.open_bugs.group(:project_id).count
  end

  # Opening a project makes it the current one and goes to its test plans.
  def show
    use_project(@project)
    redirect_to test_plans_path
  end

  def new
    @project = Project.new
  end

  def create
    @project = Project.new(project_params)
    @project.user = Current.user

    if @project.save
      use_project(@project)
      redirect_to test_plans_path, notice: t("controllers.projects.created")
    else
      render :new, status: :unprocessable_entity
    end
  end

  def edit
  end

  def update
    if @project.update(project_params)
      redirect_to projects_path, notice: t("controllers.projects.updated")
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    @project.destroy
    session.delete(:project_id) if session[:project_id] == @project.id
    redirect_to projects_path, notice: t("controllers.projects.removed")
  end

  private
    def set_project
      @project = Project.find(params[:id])
    end

    def authorize_owner_or_admin
      authorize_record_owner_or_admin(@project)
    end

    def project_params
      params.require(:project).permit(:name, :description)
    end
end
