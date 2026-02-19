class LocalesController < ApplicationController
  allow_unauthenticated_access

  def update
    locale = params[:locale].to_s
    if I18n.available_locales.map(&:to_s).include?(locale)
      cookies[:locale] = { value: locale, expires: 1.year.from_now }
    end
    redirect_back fallback_location: root_path
  end
end
