# Bug report: the bug's details, the scenarios that point to it and its
# evidence images (one per page), in the same style as EvidenceReport.
class BugReport < LatexDocument
  SECTIONS = %i[description steps_to_reproduce obtained_result expected_result].freeze

  def initialize(bug, logo: nil, locale: I18n.locale, template: File.read(self.class.template_path("bug_report")))
    super(logo: logo, template: template, locale: locale)
    @bug = bug
  end

  private
    def markers
      { "variaveis" => variables_tex, "conteudo" => content_tex }
    end

    def evidence_files
      @bug.evidence_files.to_a
    end

    def label_scope = "bug_report"

    def variables_tex
      <<~TEX.chomp
        \\newcommand{\\TituloDocumento}{#{escape(label(:title))}}
        \\newcommand{\\BugId}{\\##{@bug.id}}
        \\newcommand{\\BugTitulo}{#{escape_or_dash(@bug.title)}}
        \\newcommand{\\ReportadoPor}{#{escape_or_dash(@bug.user&.username)}}
        \\newcommand{\\DataBug}{#{format_date(@bug.created_at)}}
        \\newcommand{\\Funcionalidade}{#{escape_or_dash(@bug.feature_tag)}}
        \\newcommand{\\CausaRaiz}{#{escape_or_dash(@bug.cause_tag)}}
        \\newcommand{\\StatusBug}{#{@bug.resolved? ? "\\Resolvido" : "\\Aberto"}}
        #{logo_tex}
      TEX
    end

    def content_tex
      tex = +""
      SECTIONS.each do |attribute|
        text = @bug.public_send(attribute)
        tex << "\\secao{#{escape(label(attribute))}}\n {#{escape(text)}}\n\n" if text.present?
      end
      scenarios = @bug.test_scenarios.includes(:test_plan).to_a
      if scenarios.any?
        lines = scenarios.map do |scenario|
          "\\cenarioassociado{#{escape(scenario.test_plan.name)}}{#{escape(scenario.title)}}{#{EvidenceReport::SCENARIO_STATUS_MACROS.fetch(scenario.status, "\\Pendente")}}"
        end
        tex << "\\secao{#{escape(label(:associated_scenarios))}}\n {#{lines.join("\n  ")}}\n\n"
      end
      if evidence_files.any?
        tex << "\\clearpage\n\n"
        tex << evidence_files.map { |file| evidence_tex(file) }.join
      end
      tex.chomp
    end
end
