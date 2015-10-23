require 'active_job'

module SmsCarrier
  # Provides helper methods for testing SmsCarrier, including #assert_smses
  # and #assert_no_smses.
  module TestHelper
    include ActiveJob::TestHelper

    # Asserts that the number of SMSes sent matches the given number.
    #
    #   def test_smses
    #     assert_smses 0
    #     ContactCarrier.welcome.deliver_now
    #     assert_smses 1
    #     ContactCarrier.welcome.deliver_now
    #     assert_smses 2
    #   end
    #
    # If a block is passed, that block should cause the specified number of
    # SMSes to be sent.
    #
    #   def test_smses_again
    #     assert_smses 1 do
    #       ContactCarrier.welcome.deliver_now
    #     end
    #
    #     assert_smses 2 do
    #       ContactCarrier.welcome.deliver_now
    #       ContactCarrier.welcome.deliver_now
    #     end
    #   end
    def assert_smses(number)
      if block_given?
        original_count = SmsCarrier::Base.deliveries.size
        yield
        new_count = SmsCarrier::Base.deliveries.size
        assert_equal number, new_count - original_count, "#{number} SMSes expected, but #{new_count - original_count} were sent"
      else
        assert_equal number, SmsCarrier::Base.deliveries.size
      end
    end

    # Assert that no SMSes have been sent.
    #
    #   def test_smses
    #     assert_no_smses
    #     ContactCarrier.welcome.deliver_now
    #     assert_smses 1
    #   end
    #
    # If a block is passed, that block should not cause any SMSes to be sent.
    #
    #   def test_smses_again
    #     assert_no_smses do
    #       # No SMSes should be sent from this block
    #     end
    #   end
    #
    # Note: This assertion is simply a shortcut for:
    #
    #   assert_smses 0
    def assert_no_smses(&block)
      assert_smses 0, &block
    end
  end
end
