class Bugs::RootCausesController < ApplicationController
  def index
    @cause_counts = Bug.where.not(cause_tag: [ nil, "" ])
      .group(:cause_tag).order("count_all DESC").count
    @feature_counts = Bug.where.not(feature_tag: [ nil, "" ])
      .group(:feature_tag).order("count_all DESC").count
    @total_bugs = Bug.count
  end
end
