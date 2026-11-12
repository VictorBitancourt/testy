# Reads the most frequent bugs (by root cause and feature, with their
# descriptions) and reports the recurring problems and what to improve, as an
# unsaved BugAnalysis.
class AiBugAnalysis < AiTask
  TOP_TAGS = 5
  MAX_BUGS = 120
  TEXT_LIMIT = 400

  def initialize(project:, locale: I18n.locale, provider: nil)
    super(provider: provider)
    @project = project
    @locale = locale
  end

  def call
    bugs = sample
    return failure("There are no bugs to analyze yet.") if bugs.empty?

    run(build_prompt(bugs)) { |data| analysis_from(data, bugs) }
  end

  private

  def top_tags(column)
    @project.bugs.where.not(column => [ nil, "" ]).group(column).order("count_all DESC").limit(TOP_TAGS).count
  end

  # Bugs under the most frequent causes and features, newest first.
  def sample
    causes = top_tags(:cause_tag)
    features = top_tags(:feature_tag)
    bugs = @project.bugs
    scope = bugs.where(cause_tag: causes.keys).or(bugs.where(feature_tag: features.keys))
    scope = bugs if causes.empty? && features.empty?
    @counts = { causes: causes, features: features, total: bugs.count, open: bugs.open_bugs.count }
    scope.order(created_at: :desc).limit(MAX_BUGS).to_a
  end

  def build_prompt(bugs)
    <<~PROMPT
      You are a QA lead reviewing the team's bug history to stop the same kinds of bugs from coming back.

      Totals: #{@counts[:total]} bugs, #{@counts[:open]} still open.
      Most frequent root causes: #{format_counts(@counts[:causes])}
      Most affected features: #{format_counts(@counts[:features])}

      Bugs (from the most frequent causes and features):
      #{bugs.map { |bug| bug_line(bug) }.join("\n")}

      Find the recurring problems behind these bugs. Rules:
      - Return ONLY a JSON object: {"summary": "...", "patterns": [...], "recommendations": [...]}
      - "summary": 2-4 sentences on what the data shows overall
      - "patterns": 3 to 6 objects, most important first, each with "title", "description" (what keeps going wrong and why, citing the evidence), "recommendation" (a concrete action for dev/QA/product), "cause_tag" and "feature_tag" (from the data, or ""), and "bug_ids" (ids of the bugs that show the pattern)
      - "recommendations": 3 to 6 short, prioritized actions for the team as a whole (process, tests, code review, requirements)
      - Base every claim on the bugs above; do not invent bugs or numbers
      - Write all text in #{language_name}
    PROMPT
  end

  def format_counts(counts)
    counts.any? ? counts.map { |tag, count| "#{tag} (#{count})" }.join(", ") : "(no tags)"
  end

  def bug_line(bug)
    fields = [ "##{bug.id}", "[#{bug.status}]", "cause=#{bug.cause_tag.presence || "-"}", "feature=#{bug.feature_tag.presence || "-"}", bug.title ]
    text = [ bug.description, bug.obtained_result.presence && "Obtained: #{bug.obtained_result}" ].compact.join(" ")
    "- #{fields.join(" ")}: #{text.squish.truncate(TEXT_LIMIT)}"
  end

  def language_name
    @locale.to_s.start_with?("pt") ? "Brazilian Portuguese" : "English"
  end

  def analysis_from(data, bugs)
    raise JSON::ParserError, "Expected a JSON object" unless data.is_a?(Hash)

    known_ids = bugs.map(&:id).to_set
    patterns = Array(data["patterns"]).select { |p| p.is_a?(Hash) }.map do |p|
      {
        "title" => p["title"].to_s.strip,
        "description" => p["description"].to_s.strip,
        "recommendation" => p["recommendation"].to_s.strip,
        "cause_tag" => p["cause_tag"].to_s.strip.presence,
        "feature_tag" => p["feature_tag"].to_s.strip.presence,
        "bug_ids" => Array(p["bug_ids"]).map { |id| id.to_s.delete("#").to_i }.select { |id| known_ids.include?(id) }.uniq
      }
    end
    BugAnalysis.new(
      project: @project,
      summary: data["summary"].to_s.strip,
      patterns: patterns,
      recommendations: Array(data["recommendations"]).map { |r| r.to_s.strip.sub(/\A\d+[.)]\s*/, "") }.reject(&:empty?), # the list numbers them
      cause_counts: @counts[:causes],
      feature_counts: @counts[:features],
      bug_count: bugs.size,
      total_bugs: @counts[:total],
      ai_provider: @provider.label,
      ai_model: @provider.model
    )
  end
end
