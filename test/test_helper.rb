ENV['RAILS_ENV'] ||= 'test'
require_relative 'dummy/config/environment'

require 'minitest/autorun'
require 'minitest/stub_any_instance'
require 'awesome_print'

require 'rails/test_help'
require 'minitest/rails'
require 'minitest/reporters'
require_relative 'mock_logger'

# Include the complete backtrace?
Minitest.backtrace_filter = Minitest::BacktraceFilter.new if ENV['BACKTRACE'].present?
Rails.backtrace_cleaner.remove_silencers!
