class ProcCarrier < SmsCarrier::Base
  default to: '+886912345678',
          'X-Proc-Method' => Proc.new { Time.now.to_i.to_s },
          body: Proc.new { give_a_greeting },
          'x-has-to-proc' => :symbol

  def welcome
    sms
  end

  private

  def give_a_greeting
    "Thanks for signing up this afternoon"
  end

end
