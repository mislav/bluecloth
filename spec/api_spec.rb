require 'spec_helper'

describe BlueCloth do
  it "should be instantiable" do
    lambda { BlueCloth.new }.should_not raise_error
  end

  it "should parse README.markdown within a second" do
    readme = File.read(File.dirname(__FILE__) + '/../README.markdown')
    lambda {
      timeout(1) {
        BlueCloth.new(readme).to_html
      }
    }.should_not raise_error(Timeout::Error)
  end
end
