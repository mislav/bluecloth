require 'spec_helper'

describe BlueCloth, 'Markdown processing' do

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
  
  def load_samples
    meta_space = true
    section = section_name = sample = nil
    linenum = 0

    @sections = Hash.new { |h, k| h[k] = [] }

    begin
      File.foreach(File.dirname(__FILE__) + '/samples/all') do |line|
        linenum += 1

        # Start off in the meta section, which has sections and
        # descriptions.
        if meta_space
          case line
          # Left angles switch into data section for the current section
          # and description.
          when /^<<</
            meta_space = false
            unless sample
              sample = Sample.new(nil, section_name, linenum)
            end
          # Section headings look like:
          # ### [Code blocks]
          when /^### \[([^\]]+)\]/
            section_name = $1.chomp
            section = @sections[section_name]
          # Descriptions look like:
          # # Para plus code block
          when /^# (.*)/
            description = $1.chomp
            
            unless sample
              sample = Sample.new(description, section_name, linenum)
            else
              sample.comment << $1.chomp
            end
          end
        # Data section has input and expected output parts
        else
          case line
          # Right angles terminate a data section, at which point we
          # should have enough data to add a test.
          when /^>>>/
            section << sample
            sample = nil
            meta_space = true
          # 3-Dashed divider with text divides input from output
          when /^--- (.+)/
            sample.end_input
          # Anything else adds to either input or output
          else
            sample << line
          end
        end
      end
    rescue
      $stderr.puts "error while processing line #{linenum}"
      raise $!
    end
  end
end

class Sample
  attr_reader :comment, :section, :line
  
  def initialize(comment, section_name, line_number)
    @comment = comment
    @section = section_name
    @line = line_number
    
    @input_state = true
    @input = []
    @output = []
  end

  def end_input
    @input_state = false
  end

  def <<(line)
    ( @input_state ? @input : @output ) << line
  end

  def input
    @in_string ||= @input.join('').chomp
  end

  def output
    @out_string ||= @output.join('').chomp
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

