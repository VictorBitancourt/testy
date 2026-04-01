# frozen_string_literal: true

FerrumPdf.configure do |config|
  config.process_timeout = 30
  config.pdf_options.print_background = true
  config.browser_options = {
    "no-sandbox": true,
    "disable-dev-shm-usage": true,
    "disable-gpu": true
  }
end
