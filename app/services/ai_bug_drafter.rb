# Turns a free-text bug account (chat message, ticket, notes) into the fields
# of the bug form. Nothing is saved: the QA reviews the draft first.
class AiBugDrafter < AiTask
  FIELDS = %w[title description steps_to_reproduce obtained_result expected_result feature_tag cause_tag].freeze
  KNOWN_TAGS_LIMIT = 40

  def initialize(project:, provider: nil)
    super(provider: provider)
    @project = project
  end

  def call(text)
    return failure("Please paste the bug description.") if text.blank?

    run(build_prompt(text)) { |data| draft_from(data) }
  end

  private

  def build_prompt(text)
    <<~PROMPT
      You are a senior QA engineer writing a bug report from the notes below.

      Rules:
      - Return ONLY a JSON object with exactly these keys: #{FIELDS.map { |f| %("#{f}") }.join(", ")}
      - "title": short and specific (what breaks, where), at most 100 characters
      - "description": one or two sentences with the context and the impact
      - "steps_to_reproduce": numbered steps, one per line ("1. ...\\n2. ..."), starting from a clear initial state
      - "obtained_result": what actually happens; "expected_result": what should happen
      - "feature_tag": the affected feature; "cause_tag": the probable root cause category (e.g. validation, integration, configuration, business rule)
      - Tags are short lowercase labels. Reuse one of the known tags below whenever it fits; create a new one only if none fits
      - Use only facts from the notes; when something is unknown, use an empty string instead of inventing it
      - Write every text value in the same language as the notes

      Known feature tags: #{known_tags(:feature_tag)}
      Known cause tags: #{known_tags(:cause_tag)}

      Notes:
      #{text}
    PROMPT
  end

  def known_tags(column)
    tags = @project.bugs.where.not(column => [ nil, "" ]).group(column).order("count_all DESC").limit(KNOWN_TAGS_LIMIT).count.keys
    tags.any? ? tags.join(", ") : "(none yet)"
  end

  def draft_from(data)
    raise JSON::ParserError, "Expected a JSON object" unless data.is_a?(Hash)

    FIELDS.index_with { |field| data[field].to_s.strip }.tap do |draft|
      draft["feature_tag"] = draft["feature_tag"].downcase
      draft["cause_tag"] = draft["cause_tag"].downcase
    end
  end
end
