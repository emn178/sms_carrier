module Rails
  module Generators
    class CarrierGenerator < NamedBase
      source_root File.expand_path("../templates", __FILE__)

      argument :actions, type: :array, default: [], banner: "method method"

      check_class_collision suffix: "Carrier"

      def create_carrier_file
        template "carrier.rb", File.join('app/carriers', class_path, "#{file_name}_carrier.rb")
        if self.behavior == :invoke
          template "application_carrier.rb", 'app/carriers/application_carrier.rb'
        end
      end

      hook_for :test_framework

      protected
        def file_name
          @_file_name ||= super.gsub(/\_carrier/i, '')
        end
    end
  end
end
