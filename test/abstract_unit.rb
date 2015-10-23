require 'simplecov'
require 'coveralls'

SimpleCov.add_filter "/test/"

if ENV["COVERAGE"]
  SimpleCov.start
elsif ENV["COVERALLS"]
  SimpleCov.formatter = Coveralls::SimpleCov::Formatter
  Coveralls.wear!
end

$LOAD_PATH.unshift File.expand_path('../../lib', __FILE__)
require 'active_support/core_ext/kernel/reporting'

# These are the normal settings that will be set up by Railties
# TODO: Have these tests support other combinations of these values
silence_warnings do
  Encoding.default_internal = "UTF-8"
  Encoding.default_external = "UTF-8"
end

require 'active_support/testing/autorun'
require 'sms_carrier'
require 'sms_carrier/test_case'
require 'mocha/setup'

# Emulate AV railtie
require 'action_view'
SmsCarrier::Base.send(:include, ActionView::Layouts)

# Show backtraces for deprecated behavior for quicker cleanup.
ActiveSupport::Deprecation.debug = true

# Disable available locale checks to avoid warnings running the test suite.
I18n.enforce_available_locales = false

FIXTURE_LOAD_PATH = File.expand_path('fixtures', File.dirname(__FILE__))
SmsCarrier::Base.view_paths = FIXTURE_LOAD_PATH

module Rails
  def self.root
    File.expand_path('../', File.dirname(__FILE__))
  end
end

# Skips the current run on Rubinius using Minitest::Assertions#skip
def rubinius_skip(message = '')
  skip message if RUBY_ENGINE == 'rbx'
end
# Skips the current run on JRuby using Minitest::Assertions#skip
def jruby_skip(message = '')
  skip message if defined?(JRUBY_VERSION)
end

# FIXME: we have tests that depend on run order, we should fix that and
# remove this method call.
require 'active_support/test_case'
ActiveSupport::TestCase.test_order = :sorted
