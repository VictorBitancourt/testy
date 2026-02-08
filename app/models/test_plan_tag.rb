class TestPlanTag < ApplicationRecord
  belongs_to :test_plan
  belongs_to :tag
end
