module Positionable
  extend ActiveSupport::Concern

  included do
    before_create :set_default_position
    validates :position, numericality: { only_integer: true }, allow_nil: true
  end

  class_methods do
    def ordered
      order(position: :asc)
    end

    def highest_position
      maximum(:position) || -1
    end
  end

  def move_to!(new_position)
    update!(position: new_position)
  end

  def move_up!
    return unless position.present? && position > 0

    swap_with(position - 1)
  end

  def move_down!
    swap_with(position + 1)
  end

  private
    def set_default_position
      self.position ||= self.class.highest_position + 1
    end

    # Override in models to scope positioning within a parent record
    def positionable_scope
      self.class.all
    end

    def swap_with(other_position)
      other = positionable_scope.find_by(position: other_position)
      return unless other

      self.class.transaction do
        other.update!(position: position)
        update!(position: other_position)
      end
    end
end
