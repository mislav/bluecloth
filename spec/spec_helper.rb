require 'rubygems'
gem 'rspec', '~> 1.1.3'
require 'spec'
# gem 'mocha', '~> 0.5.6'
# require 'mocha'

require 'bluecloth'

module BlueClothHelper
  protected
  
    def markdown(input, *other)
      bluecloth(input, *other).to_html
    end

    def bluecloth(input, *other)
      BlueCloth.new(input, *other)
    end
end

Spec::Runner.configure do |config|
  # config.include My::Pony, My::Horse, :type => :farm
  config.include BlueClothHelper
  # config.predicate_matchers[:swim] = :can_swim?
  
  # config.mock_with :mocha
end
