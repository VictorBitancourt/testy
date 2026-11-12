# One AI report on the most frequent bugs (AiBugAnalysis), with the bug counts
# at the time it was made. Patterns are hashes: title, description,
# recommendation, cause_tag, feature_tag and bug_ids.
class BugAnalysis < ApplicationRecord
  belongs_to :project
  belongs_to :user, optional: true

  Pattern = Data.define(:title, :description, :recommendation, :cause_tag, :feature_tag, :bugs)

  validates :summary, presence: true

  # Patterns with their bugs loaded; bugs deleted since then are left out.
  def pattern_list
    bugs = Bug.where(id: patterns.flat_map { |p| p["bug_ids"] }).index_by(&:id)
    patterns.map do |p|
      Pattern.new(
        title: p["title"], description: p["description"], recommendation: p["recommendation"],
        cause_tag: p["cause_tag"], feature_tag: p["feature_tag"],
        bugs: Array(p["bug_ids"]).filter_map { |id| bugs[id] }
      )
    end
  end
end
