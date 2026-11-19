# Translates the text fields of a form (bug, scenario) into English. Nothing
# is saved: the form is filled with the translation for the QA to review.
class AiTranslator < AiTask
  MAX_FIELDS = 10
  MAX_LENGTH = 10_000

  def call(fields)
    fields = fields.to_h.transform_keys(&:to_s).transform_values { |value| value.to_s.strip }.compact_blank
    return failure("Nothing to translate.") if fields.empty?
    return failure("Too much text to translate.") if fields.size > MAX_FIELDS || fields.values.sum(&:length) > MAX_LENGTH

    run(build_prompt(fields)) { |data| translation_from(data, fields) }
  end

  private

  def build_prompt(fields)
    <<~PROMPT
      You are a QA engineer translating a test artifact (bug report or test scenario) into English.

      Rules:
      - Return ONLY a JSON object with exactly the same keys as the input below; each value is the English translation of that field
      - Keep the meaning, tone and level of detail; do not add, remove or fix information
      - Keep line breaks, numbering and list formatting as they are
      - Keep unchanged: text in quotes, UI labels, code, URLs, file names, product and people names
      - A field that is already in English is returned as it is

      Input:
      #{JSON.pretty_generate(fields)}
    PROMPT
  end

  def translation_from(data, fields)
    raise JSON::ParserError, "Expected a JSON object" unless data.is_a?(Hash)

    fields.keys.index_with { |key| data[key].to_s.strip.presence || fields[key] }
  end
end
