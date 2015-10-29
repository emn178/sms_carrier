module Rspec
  module Generators
		class CarrierGenerator < ::Rails::Generators::NamedBase
		  source_root File.expand_path(File.join(File.dirname(__FILE__), 'templates'))

		  def create_carrier_test
		    template 'carrier_spec.rb', File.join('spec/carriers', class_path, "#{file_name}_carrier_spec.rb")
		  end
		end
	end
end
