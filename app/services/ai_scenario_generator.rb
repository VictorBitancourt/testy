class AiScenarioGenerator < AiTask
  def initialize(test_plan, provider: nil)
    super(provider: provider)
    @test_plan = test_plan
  end

  def call(prompt)
    return failure("Please enter a feature description.") if prompt.blank?

    run(build_prompt(prompt)) { |data| create_scenarios(scenarios_from(data)) }
  end

  private

  def build_prompt(description)
    <<~PROMPT
      You are a senior QA engineer. Given the feature description below, generate test scenarios using these techniques:
      - Happy path
      - Alternative/negative paths
      - Boundary value analysis
      - Equivalence partitioning
      - Edge cases

      Rules:
      - Return ONLY a JSON object of the form {"scenarios": [...]}, no extra text
      - Each scenario object must have keys: "title", "given", "when_step", "then_step"
      - Each step must be a single sentence (no AND)
      - Match the language of the input description
      - Generate between 5 and 15 scenarios

      Feature description:
      #{description}
    PROMPT
  end

  # Accepts {"scenarios": [...]} or a bare array.
  def scenarios_from(data)
    data = data["scenarios"] if data.is_a?(Hash)
    raise JSON::ParserError, "Expected an array of scenarios" unless data.is_a?(Array)

    data
  end

  def create_scenarios(data)
    ActiveRecord::Base.transaction do
      data.map do |item|
        @test_plan.test_scenarios.create!(
          title: item["title"].to_s.strip,
          given: item["given"].to_s.strip,
          when_step: item["when_step"].to_s.strip,
          then_step: item["then_step"].to_s.strip
        )
      end
    end
  end
end
