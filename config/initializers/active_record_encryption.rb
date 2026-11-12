# Keys for `encrypts` (AI API keys in Setting). Taken from credentials when they
# exist; otherwise derived from secret_key_base, so the app works without a
# config/master.key. Changing secret_key_base makes the stored API keys unreadable.
Rails.application.config.to_prepare do
  encryption = ActiveRecord::Encryption.config
  unless encryption.has_primary_key?
    derive = ->(purpose) { Rails.application.key_generator.generate_key("active_record_encryption/#{purpose}", 32).unpack1("H*") }
    encryption.primary_key = derive.("primary_key")
    encryption.deterministic_key = derive.("deterministic_key")
    encryption.key_derivation_salt = derive.("key_derivation_salt")
  end
end
