module Taggable
  extend ActiveSupport::Concern

  included do
    has_many :test_plan_tags,
             class_name: "TestPlanTag",
             foreign_key: :test_plan_id,
             dependent: :destroy,
             inverse_of: :test_plan
    has_many :tags, through: :test_plan_tags
  end

  class_methods do
    def tagged_with(name)
      joins(:tags).where(tags: { name: name })
    end
  end

  def tag_list
    tags.pluck(:name).join(", ")
  end

  def tag_list=(names)
    tag_names = names.split(",").map(&:strip).reject(&:blank?).uniq

    self.tags = tag_names.map do |name|
      Tag.find_or_create_by(name: name.downcase)
    end
  end
end
