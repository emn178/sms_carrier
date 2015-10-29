module TestUnit
  module Generators
		class CarrierGenerator < ::Rails::Generators::NamedBase
		  source_root File.expand_path(File.join(File.dirname(__FILE__), 'templates'))

		  def create_carrier_test
		    template 'carrier_test.rb', File.join('test/carriers', class_path, "#{file_name}_carrier_test.rb")
		  end
		end
	end
end
