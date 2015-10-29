<% module_namespacing do -%>
class <%= class_name %>Carrier < ApplicationCarrier
<% actions.each do |action| -%>
  def <%= action %>
    @greeting = "Hi"

    sms to: "+88612345678"
  end
<% end -%>
end
<% end -%>
