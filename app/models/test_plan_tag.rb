class TestPlanTag < ApplicationRecord
  belongs_to :test_plan, inverse_of: :test_plan_tags
  belongs_to :tag
end
