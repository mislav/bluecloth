require 'spec_helper'
require 'sample_loader'

describe BlueCloth, 'Markdown processing' do

  extend SampleLoader
  
  it "should render HTML without trailing newline" do
    BlueCloth.new('Foo').to_html.should == '<p>Foo</p>'
  end

  it "should not swallow trailing newline" do
    BlueCloth.new("Foo\n").to_html.should == "<p>Foo</p>\n"
  end

  describe 'sample:' do
    load_samples('all') do |sample|
      it(sample.comment) { sample.should render }
    end
    
    load_samples('failing') do |sample|
      it(sample.comment) { sample.should render }
    end if false
  end
  
  protected
  
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
    "%s (line %d):\n<<<\n%s\n---\n%s\n>>>\n%s\n===" % [
      @sample.comment, @sample.line,
      @sample.input,
      @sample.output,
      @result
    ]
  end
  
  # def negative_failure_message
  #   "expected #{@target.inspect} not to be in Zone #{@expected}"
  # end
end

