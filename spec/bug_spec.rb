# Unit test for bugs found in BlueCloth
require 'spec_helper'

describe BlueCloth, 'bugs' do

	include SampleLoader

  it "should not regexp engine overflow" do
		contents = File::read sample_file("re-overflow.txt")
		lambda { markdown(contents) }.should_not raise_error
	end
	
  it "should not regexp engine overflow" do
		contents = File::read sample_file("re-overflow2.txt")
		lambda { markdown(contents) }.should_not raise_error
	end
	
  it "2 character bold asterisks" do
		markdown("**aa**").should == "<p><strong>aa</strong></p>"
	end

  it "should correctly emphasize two character words with asterisks" do
    markdown("*aa*").should == "<p><em>aa</em></p>"
	end
	
  it "should correctly emphasize two character words with underscores" do
    markdown("_aa_").should == "<p><em>aa</em></p>"
	end

	it "should not raise ArgumentError when ruby enables warnings" do
		oldverbose = $VERBOSE
    begin
      $VERBOSE = true
      lambda { markdown("*woo*") }.should_not raise_error
    ensure
      $VERBOSE = oldverbose
    end
	end
	
end
