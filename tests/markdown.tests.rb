#!/usr/bin/ruby
#
# Test case for BlueCloth Markdown transforms.
# $Id: TEMPLATE.rb.tpl,v 1.2 2003/09/11 04:59:51 deveiant Exp $
#
# Copyright (c) 2004, 2005 The FaerieMUD Consortium.
# 

if !defined?( BlueCloth ) || !defined?( BlueCloth::TestCase )
	basedir = File::dirname( __FILE__ )
	require File::join( basedir, 'bctestcase' )
end


### Test conformance to Markdown syntax specification
class MarkdownTestCase < BlueCloth::TestCase

	### Test email address output
	Emails = %w[
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

	def test_10_email_address
		printTestHeader "BlueCloth: Inline email address"
		rval = match = nil

		Emails.each {|addr|
			assert_nothing_raised {
				rval = BlueCloth::new( "<#{addr}>" ).to_html
			}

			match = %r{<p><a href="([^\"]+)">[^<]+</a></p>}.match( rval )
			assert_not_nil match, "Match against output #{rval}"
			assert_equal "mailto:#{addr}", decode( match[1] )
		}
	end


	def decode( str )
		str.gsub( /&#(x[a-f0-9]+|\d{3});/i ) {|match|
			code = $1
			debugMsg "Decoding %p" % code

			case code
			when /^x([a-f0-9]+)/i
				debugMsg "  (hex) = %p" % $1.to_i(16).chr
				$1.to_i(16).chr
			when /\d{3}/
				debugMsg "  (oct) = %p" % code.to_i.chr
				code.to_i.chr
			else
				raise "Hmmm... malformed entity %p" % code
			end
		} 
	end



	#################################################################
	###	A U T O - G E N E R A T E D   T E S T S
	#################################################################

	# Parse the data section into a hash of test specifications
	TestSets = {}
	begin
		seenEnd = false
		inMetaSection = true
		inInputSection = true
		section, description, input, output = '', '', '', ''
		linenum = 0

		# Read this file, skipping lines until the __END__ token. Then start
		# reading the tests.
		File::foreach( __FILE__ ) {|line|
			linenum += 1
			if /^__END__/ =~ line then seenEnd = true; next end
			debugMsg "#{linenum}: #{line.chomp}"
			next unless seenEnd

			# Start off in the meta section, which has sections and
			# descriptions.
			if inMetaSection
				
				case line

				# Left angles switch into data section for the current section
				# and description.
				when /^<<</
					inMetaSection = false
					next

				# Section headings look like:
				# ### [Code blocks]
				when /^### \[([^\]]+)\]/
					section = $1.chomp
					TestSets[ section ] ||= {}

				# Descriptions look like:
				# # Para plus code block
				when /^# (.*)/
					description = $1.chomp
					TestSets[ section ][ description ] ||= {
						:line => linenum,
						:sets => [],
					}

				end

			# Data section has input and expected output parts
			else

				case line

				# Right angles terminate a data section, at which point we
				# should have enough data to add a test.
				when /^>>>/
					TestSets[ section ][ description ][:sets] << [ input.chomp, output.chomp ]

					inMetaSection = true
					inInputSection = true
					input = ''; output = ''

				# 3-Dashed divider with text divides input from output
				when /^--- (.+)/
					inInputSection = false

				# Anything else adds to either input or output
				else
					if inInputSection
						input += line
					else
						output += line
					end
				end
			end
		}			
	end

	debugMsg "Test sets: %p" % TestSets

	# Auto-generate tests out of the test specifications
	TestSets.each {|sname, section|

		# Generate a test method for each section
		section.each do |desc, test|
			methname = "test_%03d_%s" %
				[ test[:line], desc.gsub(/\W+/, '_').downcase ]

			# Header
			code = %{
				def #{methname}
					printTestHeader "BlueCloth: #{desc}"
					rval = nil
			}

			# An assertion for each input/output pair
			test[:sets].each {|input, output|
				code << %{
					assert_nothing_raised {
						obj = BlueCloth::new(%p)
						rval = obj.to_html
					}
					assert_equal %p, rval

				} % [ input, output ]
			}

			code << %{
				end
			}

			# Strip leading indent for prettier output of the code in debugging
			code.gsub!( /^\t{4}/, '' )

			# Support debugging for individual tests
			olddb = nil
			if $DebugPattern && $DebugPattern =~ methname
				olddb = $DEBUG
				$DEBUG = true
			end

			debugMsg "--- %s [%s]:\n%s\n---\n" % [sname, desc, code]

			$DEBUG = olddb unless olddb.nil?
			eval code
		end

	}

end


__END__

