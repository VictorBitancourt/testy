module Result
  class Base
    attr_reader :data, :error

    def initialize(data = nil, error = nil)
      @data = data
      @error = error
    end

    def success?
      is_a?(Success)
    end

    def failure?
      is_a?(Failure)
    end
  end

  class Success < Base
    def initialize(data = nil)
      super(data, nil)
    end
  end

  class Failure < Base
    def initialize(error)
      super(nil, error)
    end
  end

  def self.success(data = nil)
    Success.new(data)
  end

  def self.failure(error)
    Failure.new(error)
  end
end
