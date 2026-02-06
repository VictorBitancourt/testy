ENV["RAILS_ENV"] ||= "test"
require_relative "../config/environment"

require "rails/test_help"
require "webmock/minitest"
require "vcr"
require "mocha/minitest"

WebMock.allow_net_connect!

VCR.configure do |config|
  config.allow_http_connections_when_no_cassette = true
  config.cassette_library_dir = "test/vcr_cassettes"
  config.hook_into :webmock
  config.filter_sensitive_data("<GEMINI_API_KEY>") { ENV["GEMINI_API_KEY"] }
  config.default_cassette_options = {
    match_requests_on: [ :method, :uri, :body ]
  }
end

require_relative "test_helpers/ai_api_test_helper"
require_relative "test_helpers/session_test_helper"

module ActiveSupport
  class TestCase
    parallelize(workers: :number_of_processors)

    fixtures :all

    include ActiveJob::TestHelper
    include AiApiTestHelper

    teardown do
      Current.clear_all
    end
  end
end

class ActionDispatch::IntegrationTest
  include SessionTestHelper
end

class ActionDispatch::SystemTestCase
  include SessionTestHelper

  def setup
    super
    Capybara.default_max_wait_time = 10
  end
end

module FixturesTestHelper
  extend ActiveSupport::Concern

  class_methods do
    def identify(label, column_type = :integer)
      if label.to_s.end_with?("_uuid")
        column_type = :uuid
        label = label.to_s.delete_suffix("_uuid")
      end

      return super(label, column_type) unless column_type.in?([ :uuid, :string ])
      generate_fixture_uuid(label)
    end

    private

    def generate_fixture_uuid(label)
      fixture_int = Zlib.crc32("fixtures/#{label}") % (2**30 - 1)

      base_time = Time.utc(2024, 1, 1, 0, 0, 0)
      timestamp = base_time + (fixture_int / 1000.0)

      uuid_v7_with_timestamp(timestamp, label)
    end

    def uuid_v7_with_timestamp(time, seed_string)
      time_ms = time.to_f * 1000
      timestamp_ms = time_ms.to_i

      bytes = []
      bytes[0] = (timestamp_ms >> 40) & 0xff
      bytes[1] = (timestamp_ms >> 32) & 0xff
      bytes[2] = (timestamp_ms >> 24) & 0xff
      bytes[3] = (timestamp_ms >> 16) & 0xff
      bytes[4] = (timestamp_ms >> 8) & 0xff
      bytes[5] = timestamp_ms & 0xff

      frac_ms = time_ms - timestamp_ms
      sub_ms_precision = (frac_ms * 4096).to_i & 0xfff

      hash = Digest::MD5.hexdigest(seed_string)

      bytes[6] = ((sub_ms_precision >> 8) & 0x0f) | 0x70
      bytes[7] = sub_ms_precision & 0xff

      rand_b = hash[3...19].to_i(16) & ((2**62) - 1)
      bytes[8] = ((rand_b >> 56) & 0x3f) | 0x80
      bytes[9] = (rand_b >> 48) & 0xff
      bytes[10] = (rand_b >> 40) & 0xff
      bytes[11] = (rand_b >> 32) & 0xff
      bytes[12] = (rand_b >> 24) & 0xff
      bytes[13] = (rand_b >> 16) & 0xff
      bytes[14] = (rand_b >> 8) & 0xff
      bytes[15] = rand_b & 0xff

      uuid = "%02x%02x%02x%02x-%02x%02x-%02x%02x-%02x%02x-%02x%02x%02x%02x%02x%02x" % bytes
      ActiveRecord::Type::Uuid.hex_to_base36(uuid.delete("-"))
    end
  end
end

ActiveSupport.on_load(:active_record_fixture_set) do
  prepend(FixturesTestHelper)
end
