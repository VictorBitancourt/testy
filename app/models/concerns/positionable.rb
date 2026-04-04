module Positionable
  extend ActiveSupport::Concern

  included do
    before_create :set_default_position
    validates :position, numericality: { only_integer: true }, allow_nil: true
  end

  class_methods do
    def highest_position
      maximum(:position) || -1
    end
  end

  private
    def set_default_position
      self.position ||= self.class.highest_position + 1
    end
end
