module Api
  module V1
    class ProjectsController < BaseController
      def index
        projects = Project.includes(:user).order(:name)
        plan_counts = TestPlan.group(:project_id).count
        open_bug_counts = Bug.open_bugs.group(:project_id).count

        render json: {
          projects: projects.map { |p| serialize_project(p, plan_counts[p.id].to_i, open_bug_counts[p.id].to_i) }
        }
      end

      def show
        project = Project.find(params[:id])

        render json: { project: serialize_project(project, project.test_plans.count, project.bugs.open_bugs.count) }
      end

      def create
        project = Project.new(project_params)
        project.user = current_api_user

        if project.save
          render json: { project: serialize_project(project, 0, 0) }, status: :created
        else
          render_errors(project)
        end
      end

      private

      def project_params
        params.require(:project).permit(:name, :description)
      end

      def serialize_project(project, test_plans_count, open_bugs_count)
        {
          id: project.id,
          name: project.name,
          description: project.description,
          test_plans_count: test_plans_count,
          open_bugs_count: open_bugs_count,
          user: project.user ? { id: project.user.id, username: project.user.username } : nil,
          created_at: project.created_at,
          updated_at: project.updated_at
        }
      end
    end
  end
end
