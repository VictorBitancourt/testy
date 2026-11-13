class ApplicationController < ActionController::Base
  include Authentication
  include CurrentProject
  # Only allow modern browsers supporting webp images, web push, badges, import maps, CSS nesting, and CSS :has.
  allow_browser versions: :modern

  # Changes to the importmap will invalidate the etag for HTML responses
  stale_when_importmap_changes

  around_action :switch_locale

  private

  # PDFs open in the browser; ?download=1 saves them instead.
  def pdf_disposition
    params[:download].present? ? :attachment : :inline
  end

  # Per request, so the locale never leaks into the next request on the same thread.
  def switch_locale(&action)
    locale = params[:locale] || cookies[:locale] || I18n.default_locale
    locale = I18n.default_locale unless I18n.available_locales.map(&:to_s).include?(locale.to_s)
    I18n.with_locale(locale, &action)
  end
end
