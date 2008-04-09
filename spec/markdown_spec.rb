require 'spec_helper'
require 'sample_loader'

describe BlueCloth, 'Markdown processing' do

  include SampleLoader
  
  before(:all) do
    load_samples
  end

  it "should render HTML without trailing newline" do
    BlueCloth.new('Foo').to_html.should == '<p>Foo</p>'
  end

  it "should not swallow trailing newline" do
    BlueCloth.new("Foo\n").to_html.should == "<p>Foo</p>\n"
  end
  
  it "should render all the samples correctly" do
    @sections.values.each do |samples|
      samples.each do |sample|
        sample.should render
      end
    end
  end

  def render
    SampleMatcher.new
  end
end

class SampleMatcher
  # def initialize(expected)
  #   @expected = expected
  # end
  
  def matches?(sample)
    @sample = sample
    @result = BlueCloth.new(@sample.input).to_html
    @result.eql?(@sample.output)
  end
  
  def failure_message
    <<-MSG
    #{@sample.comment} (line #{@sample.line}):
    <<<
    #{@sample.input}---
    #{@sample.output}>>>
    #{@result}===
    MSG
  end
  
  def negative_failure_message
    "expected #{@target.inspect} not to be in Zone #{@expected}"
  end
end

