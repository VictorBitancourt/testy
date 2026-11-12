class Bugs::RootCausesController < ApplicationController
  before_action :require_project

  def index
    bugs = current_project.bugs
    @cause_counts = bugs.where.not(cause_tag: [ nil, "" ])
      .group(:cause_tag).order("count_all DESC").count
    @feature_counts = bugs.where.not(feature_tag: [ nil, "" ])
      .group(:feature_tag).order("count_all DESC").count
    @total_bugs = bugs.count
    @analysis = current_project.bug_analyses.includes(:user).order(:created_at).last
  end
end
