# PDF of a saved BugAnalysis (recurring bug analysis), in the same style as the
# other LaTeX reports.
class BugAnalysisReport < LatexDocument
  BAR_MAX_CM = 8.0

  def initialize(analysis, logo: nil, locale: I18n.locale, template: File.read(self.class.template_path("bug_analysis_report")))
    super(logo: logo, template: template, locale: locale)
    @analysis = analysis
  end

  private
    def markers
      { "variaveis" => variables_tex, "conteudo" => content_tex }
    end

    def evidence_files
      []
    end

    def label_scope = "bug_analysis"

    def variables_tex
      <<~TEX.chomp
        \\newcommand{\\TituloDocumento}{#{escape(label(:title))}}
        \\newcommand{\\DataAnalise}{#{escape(I18n.l(@analysis.created_at, format: :short_datetime, locale: @locale))}}
        \\newcommand{\\GeradoPor}{#{escape_or_dash(@analysis.user&.username)}}
        \\newcommand{\\BugsAnalisados}{#{@analysis.bug_count}}
        \\newcommand{\\TotalBugs}{#{@analysis.total_bugs}}
        \\newcommand{\\ModeloIA}{#{escape_or_dash([ @analysis.ai_provider, @analysis.ai_model ].compact.join(" · "))}}
        #{logo_tex}
      TEX
    end

    def content_tex
      tex = +"\\secao{#{escape(label(:summary))}}\n {#{escape_or_dash(@analysis.summary)}}\n\n"
      tex << chart_tex(label(:top_causes), @analysis.cause_counts)
      tex << chart_tex(label(:top_features), @analysis.feature_counts)

      patterns = @analysis.pattern_list
      if patterns.any?
        tex << "\\needspace{12\\baselineskip}\n{\\Large\\bfseries #{escape(label(:common_errors))}}\\par\n\n"
        patterns.each_with_index { |pattern, index| tex << pattern_tex(pattern, index + 1) }
      end

      if @analysis.recommendations.any?
        items = @analysis.recommendations.map { |r| "  \\item #{escape(r)}" }.join("\n")
        tex << "\\secao{#{escape(label(:to_avoid))}}\n {\\begin{enumerate}\n#{items}\n\\end{enumerate}}\n\n"
      end
      tex.chomp
    end

    def chart_tex(heading, counts)
      return "" if counts.blank?

      max = counts.values.max.to_f
      rows = counts.map { |tag, count| "  \\barra{#{escape(tag)}}{#{count}}{#{(count / max * BAR_MAX_CM).round(2)}cm}" }
      "\\secao{#{escape(heading)}}\n {\\begin{tabularx}{\\linewidth}{>{\\raggedright\\arraybackslash}p{4.2cm} r X}\n#{rows.join("\n")}\n\\end{tabularx}}\n\n"
    end

    def pattern_tex(pattern, number)
      tags = [ pattern.cause_tag && "#{escape(label(:cause))}: #{escape(pattern.cause_tag)}", pattern.feature_tag && "#{escape(label(:feature))}: #{escape(pattern.feature_tag)}" ].compact.join(" \\textperiodcentered{} ")
      bugs = pattern.bugs.map { |bug| "\\##{bug.id} #{escape(bug.title)}" }.join("; ")
      "\\padrao{#{number}}\n {#{escape_or_dash(pattern.title)}}\n {#{tags}}\n {#{escape_or_dash(pattern.description)}}\n {#{escape_or_dash(pattern.recommendation)}}\n {#{bugs}}\n\n"
    end
end
