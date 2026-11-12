# Test execution evidence for a test plan: every scenario with its status,
# each followed by its evidence images (one per page).
class EvidenceReport < LatexDocument
  SCENARIO_STATUS_MACROS = {
    "approved" => "\\Aprovado",
    "failed" => "\\Reprovado",
    "pending" => "\\Pendente"
  }.freeze

  def initialize(test_plan, logo: nil, locale: I18n.locale, template: File.read(self.class.template_path("evidence_report")))
    super(logo: logo, template: template, locale: locale)
    @test_plan = test_plan
  end

  def scenarios
    @test_plan.test_scenarios
  end

  private
    def markers
      { "variaveis" => variables_tex, "cenarios" => scenarios_tex }
    end

    def evidence_files
      scenarios.flat_map { |scenario| scenario.evidence_files.to_a }
    end

    def label_scope = "evidence_report"

    def variables_tex
      <<~TEX.chomp
        \\newcommand{\\QAResponsavel}{#{escape_or_dash(@test_plan.qa_name)}}
        \\newcommand{\\NumeroCenarios}{#{scenarios.size}}
        \\newcommand{\\Historia}{#{escape_or_dash(@test_plan.name)}}
        \\newcommand{\\StatusEvidencia}{#{plan_status_macro}}
        \\newcommand{\\TituloDocumento}{#{escape(label(:title))}}
        #{logo_tex}
      TEX
    end

    # Approved only when every scenario is; failed as soon as one fails.
    def plan_status_macro
      if scenarios.any? && scenarios.all? { |s| s.status == "approved" }
        "\\Aprovado"
      elsif scenarios.any? { |s| s.status == "failed" }
        "\\Reprovado"
      else
        "\\Pendente"
      end
    end

    def scenarios_tex
      scenarios.each_with_index.map do |scenario, index|
        tex = +<<~TEX
          % ==========================================================
          % CENÁRIO #{index + 1}
          % ==========================================================

          \\cenario[#{SCENARIO_STATUS_MACROS.fetch(scenario.status, "\\Pendente")}]
           {#{escape_or_dash(scenario.title)}}
           {#{escape_or_dash(strip_keyword(scenario.given, "(dado\\s+)?que|given"))}}
           {#{escape_or_dash(strip_keyword(scenario.when_step, "quando|when"))}}
           {#{escape_or_dash(strip_keyword(scenario.then_step, "ent[ãa]o|then"))}}

        TEX
        tex << "\\defeito{#{escape(scenario.bug.display_name)}}\n\n" if scenario.bug
        files = scenario.evidence_files.to_a
        tex << (files.any? ? files.map { |file| evidence_tex(file) }.join : "\\clearpage\n\n")
      end.join.chomp
    end

    # The template already prints "Dado que"/"Given", "Quando"/"When" and "Então"/"Then".
    def strip_keyword(text, keyword)
      text.to_s.strip.sub(/\A(?:#{keyword})\b[\s,:]*/i, "")
    end
end
