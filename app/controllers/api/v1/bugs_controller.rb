module Api
  module V1
    class BugsController < BaseController
      before_action :set_bug, only: [ :show, :update, :destroy ]
      before_action -> { authorize_owner_or_admin!(@bug) }, only: [ :update, :destroy ]

      def index
        bugs = Bug.includes(:user).order(created_at: :desc)

        bugs = bugs.where(status: params[:status]) if params[:status].present?
        bugs = bugs.by_feature(params[:feature_tag])
        bugs = bugs.by_cause(params[:cause_tag])
        bugs = bugs.created_from(params[:date_from]) if params[:date_from].present?
        bugs = bugs.created_until(params[:date_until]) if params[:date_until].present?
        bugs = bugs.search(params[:search]) if params[:search].present?

        pagy, bugs = pagy(bugs)

        render json: {
          bugs: bugs.map { |b| serialize_bug(b) },
          meta: pagination_meta(pagy)
        }
      end

      def show
        render json: { bug: serialize_bug_detail(@bug) }
      end

      def create
        bug = Bug.new(bug_params)
        bug.user = current_api_user

        if bug.save
          render json: { bug: serialize_bug(bug) }, status: :created
        else
          render_errors(bug)
        end
      end

      def update
        if @bug.update(bug_params)
          render json: { bug: serialize_bug(@bug) }
        else
          render_errors(@bug)
        end
      end

      def destroy
        @bug.destroy!
        head :no_content
      end

      private

      def set_bug
        @bug = Bug.find(params[:id])
      end

      def bug_params
        params.require(:bug).permit(:title, :description, :steps_to_reproduce, :obtained_result, :expected_result, :feature_tag, :cause_tag, :status)
      end

      def serialize_bug(bug)
        {
          id: bug.id,
          title: bug.title,
          description: bug.description,
          status: bug.status,
          feature_tag: bug.feature_tag,
          cause_tag: bug.cause_tag,
          user: bug.user ? { id: bug.user.id, username: bug.user.username } : nil,
          created_at: bug.created_at,
          updated_at: bug.updated_at
        }
      end

      def serialize_bug_detail(bug)
        serialize_bug(bug).merge(
          steps_to_reproduce: bug.steps_to_reproduce,
          obtained_result: bug.obtained_result,
          expected_result: bug.expected_result
        )
      end
    end
  end
end
