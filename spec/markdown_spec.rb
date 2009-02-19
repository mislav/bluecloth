require 'spec_helper'

describe BlueCloth, 'Markdown processing' do

  extend SampleLoader
  
  it "should render HTML without trailing newline" do
    markdown('Foo').should == '<p>Foo</p>'
  end

  it "should not swallow trailing newline" do
    pending
    markdown("Foo\n").should == "<p>Foo</p>\n"
  end

  describe 'sample:' do
    load_samples('all', 'code', 'titles', 'emphasis', 'links', 'lists') do |sample|
      it(sample.comment) { sample.should render }
    end
    
    load_samples('failing') do |sample|
      it(sample.comment) { pending; sample.should render }
    end
  end

  it "should render mailto:links for funky emails" do
    emails = %w[
      address@example.com
      foo-list-admin@bar.com
      fu@bar.COM
      baz@ruby-lang.org
      foo-tim-bazzle@bar-hop.co.uk
      littlestar@twinkle.twinkle.band.CO.ZA
      ll@lll.lllll.ll
      Ull@Ulll.Ulllll.ll
      UUUU1@UU1.UU1UUU.UU
      l@ll.ll
      Ull.Ullll@llll.ll
      Ulll-Ull.Ulllll@ll.ll
      1@111.ll
    ]
    # I can't see a way to handle IDNs clearly yet, so these will have to wait.
    #	info@öko.de
    #	jemand@büro.de
    #	irgendwo-interreßant@dÅgta.se
    #]
    
    emails.each do |email|
      rval = markdown "<#{email}>"

      match = %r{<p><a href="([^\"]+)">[^<]+</a></p>}.match(rval)
      match.should_not be_nil
      decode(match[1]).should == "mailto:#{email}"
    end
  end
  
  protected
    
    def render
      SampleMatcher.new
    end
    
    def decode( str )
      str.gsub(/&#(x[a-f0-9]+|\d{3});/i) do |match|
        code = $1

        case code
        when /^x([a-f0-9]+)/i
          $1.to_i(16).chr
        when /\d{3}/
          code.to_i.chr
        else
          raise "Hmmm... malformed entity %p" % code
        end
      end
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
    "%s (line %d):\n<<< input:\n%s\n--- expected:\n%s\n>>> actual:\n%s\n===" % [
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

