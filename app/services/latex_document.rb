require "open3"
require "tmpdir"

# A PDF built from a LaTeX template in lib/templates and compiled with pdflatex.
# Subclasses return the text for each "% testy:<marker>" line of the template
# from #markers, list the evidence attachments they cite in #evidence_files and
# name their labels in config/locales/*/reports.yml with #label_scope. The
# "% testy:rotulos" line gets those labels, in the given locale, as \T<Key> macros.
class LatexDocument
  class Error < StandardError; end

  # Formats \includegraphics understands under pdflatex.
  EMBEDDABLE_EXTENSIONS = {
    "image/png" => "png",
    "image/jpeg" => "jpg",
    "application/pdf" => "pdf"
  }.freeze
  PDFLATEX_RUNS = 2 # the second run resolves \pageref{LastPage}
  JOB_NAME = "documento".freeze

  LATEX_SPECIALS = {
    "\\" => "\\textbackslash{}", "{" => "\\{", "}" => "\\}", "$" => "\\$",
    "&" => "\\&", "#" => "\\#", "%" => "\\%", "_" => "\\_",
    "~" => "\\textasciitilde{}", "^" => "\\textasciicircum{}"
  }.freeze
  TYPOGRAPHY = {
    "“" => "``", "”" => "''", "‘" => "`", "’" => "'",
    "–" => "--", "—" => "---", "…" => "\\ldots{}", "•" => "\\textbullet{}"
  }.freeze

  def self.template_path(name)
    Rails.root.join("lib/templates/#{name}.tex")
  end

  def self.escape(text)
    text.to_s
      .unicode_normalize(:nfc)
      .gsub(/\r\n?/, "\n")
      .gsub(/[\\{}$&#%_~^]/) { |c| LATEX_SPECIALS.fetch(c) }
      .gsub(/"([^"\n]*)"/) { "``#{$1}''" }
      .gsub(/[“”‘’–—…•]/) { |c| TYPOGRAPHY.fetch(c) }
      .gsub(/[^\n\u0020-\u017f]/, "") # outside what T1 + inputenc can typeset (emoji etc.)
      .strip
      .gsub(/\s*\n\s*\n\s*/, "\\par ")
      .gsub(/\s*\n\s*/, "\\newline ")
  end

  def initialize(logo:, template:, locale: I18n.locale)
    @logo = logo
    @template = template
    @locale = locale
  end

  def to_tex
    @template.each_line.map do |line|
      marker = line.strip[/\A% testy:(\w+)\z/, 1]
      marker ? "#{markers.merge("rotulos" => labels_tex).fetch(marker)}\n" : line
    end.join
  end

  def to_pdf
    Dir.mktmpdir("testy-latex") do |dir|
      File.binwrite(File.join(dir, logo_name), @logo.download) if @logo
      evidence_files.select { |file| embeddable?(file) }.each do |file|
        File.binwrite(File.join(dir, asset_name(file)), file.download)
      end
      File.write(File.join(dir, "#{JOB_NAME}.tex"), to_tex)
      PDFLATEX_RUNS.times { run_pdflatex(dir) }
      File.binread(File.join(dir, "#{JOB_NAME}.pdf"))
    end
  end

  private
    def markers
      raise NotImplementedError
    end

    def evidence_files
      raise NotImplementedError
    end

    def label_scope
      raise NotImplementedError
    end

    def label(key)
      I18n.t("reports.#{label_scope}.#{key}", locale: @locale, default: :"reports.common.#{key}")
    end

    def labels_tex
      labels = I18n.t("reports.common", locale: @locale).merge(I18n.t("reports.#{label_scope}", locale: @locale))
      labels.map { |key, text| "\\newcommand{\\T#{key.to_s.camelize}}{#{escape(text)}}" }.join("\n")
    end

    def format_date(time)
      time ? I18n.l(time.to_date, format: :short_date, locale: @locale) : "---"
    end

    def escape(text)
      self.class.escape(text)
    end

    def escape_or_dash(text)
      escape(text).presence || "---"
    end

    def logo_tex
      "\\newcommand{\\Logo}{#{@logo ? "\\includegraphics[width=6cm,height=2.2cm,keepaspectratio]{#{logo_name}}" : ""}}"
    end

    # One evidence per page: the figure is 62% of the text height.
    def evidence_tex(file)
      caption = escape(file.caption.presence || file.filename.to_s)
      figure = embeddable?(file) ? "\\evidencia{#{asset_name(file)}}{#{caption}}" : "\\evidenciaindisponivel{#{caption}}"
      "#{figure}\n\n\\clearpage\n\n"
    end

    def embeddable?(file)
      EMBEDDABLE_EXTENSIONS.key?(file.content_type)
    end

    def asset_name(file)
      "evidencia-#{file.id}.#{EMBEDDABLE_EXTENSIONS.fetch(file.content_type)}"
    end

    def logo_name
      "logo.#{EMBEDDABLE_EXTENSIONS.fetch(@logo.content_type, "jpg")}"
    end

    def run_pdflatex(dir)
      command = [ ENV.fetch("PDFLATEX", "pdflatex"), "-interaction=nonstopmode", "-halt-on-error", "-no-shell-escape", "#{JOB_NAME}.tex" ]
      output, status = Open3.capture2e(*command, chdir: dir)
      unless status.success?
        reason = output.scrub.lines.find { |l| l.start_with?("!") }&.delete_prefix("!")&.strip
        raise Error, "#{I18n.t("reports.errors.pdflatex_failed", reason: reason || I18n.t("reports.errors.see_log"))}\n#{output.scrub.lines.last(15).join}"
      end
    rescue Errno::ENOENT
      raise Error, I18n.t("reports.errors.pdflatex_missing")
    end
end
