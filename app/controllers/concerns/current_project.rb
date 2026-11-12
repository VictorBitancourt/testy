# The project (workspace) being worked on, kept in the session. With a single
# project it is picked automatically; opening a plan or bug of another project
# switches to it.
module CurrentProject
  extend ActiveSupport::Concern

  included do
    helper_method :current_project
  end

  private
    def current_project
      return @current_project if defined?(@current_project)

      @current_project = Project.find_by(id: session[:project_id])
      @current_project ||= Project.first.tap { |only| session[:project_id] = only.id } if Project.count == 1
      @current_project
    end

    def require_project
      redirect_to projects_path, alert: t("controllers.projects.choose_first") unless current_project
    end

    def use_project(project)
      session[:project_id] = project.id
      @current_project = project
    end
end
