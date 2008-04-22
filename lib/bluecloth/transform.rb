require 'digest/md5'
require 'strscan'

module BlueCloth::Transform
  
  # Render Markdown-formatted text in this string object as HTML and return it.
  # The parameter is for compatibility with RedCloth, and is currently unused,
  # though that may change in the future.
	def to_html(lite = false)
		# Create a StringScanner we can reuse for various lexing tasks
		@scanner = StringScanner::new( '' )

		# Make a structure to carry around stuff that gets placeholdered out of
		# the source.
		rs = RenderState::new( {}, {}, {} )

		# Make a copy of the string with normalized line endings, tabs turned to
		# spaces, and a couple of guaranteed newlines at the end
		text = detab @content.gsub(/\r\n?/, "\n")
		text += "\n\n"
		@log.debug "Normalized line-endings: %p" % text

		# Filter HTML if we're asked to do so
		if filter_html
			text.gsub!( "<", "&lt;" )
			text.gsub!( ">", "&gt;" )
			@log.debug "Filtered HTML: %p" % text
		end

		# Simplify blank lines
		text.gsub! /^ +$/, ''
		@log.debug "Tabs -> spaces/blank lines stripped: %p" % text

		# Replace HTML blocks with placeholders
		text = hide_html_blocks( text, rs )
		@log.debug "Hid HTML blocks: %p" % text
		@log.debug "Render state: %p" % rs

		# Strip link definitions, store in render state
		text = strip_link_definitions( text, rs )
		@log.debug "Stripped link definitions: %p" % text
		@log.debug "Render state: %p" % rs

		# Escape meta-characters
		text = escape_special_chars( text )
		@log.debug "Escaped special characters: %p" % text

		# Transform block-level constructs
		text = apply_block_transforms( text, rs )
		@log.debug "After block-level transforms: %p" % text

		# Now swap back in all the escaped characters
		text = unescape_special_chars( text )
		@log.debug "After unescaping special characters: %p" % text

		return text
	end

	# Exception class for formatting errors.
	class FormatError < RuntimeError
    # Create a new FormatError with the given source +str+ and an optional
    # message about the +specific+ error.
		def initialize(str, specific = nil)
			if specific
				msg = "Bad markdown format near %p: %s" % [ str, specific ]
			else
				msg = "Bad markdown format near %p" % str
			end

			super( msg )
		end
	end

	# Rendering state struct. Keeps track of URLs, titles, and HTML blocks
	# midway through a render. I prefer this to the globals of the Perl version
	# because globals make me break out in hives. Or something.
	RenderState = Struct::new "RenderState", :urls, :titles, :html_blocks, :log

	# Tab width for #detab if none is specified
	TabWidth = 4

	# The tag-closing string -- set to '>' for HTML
	EmptyElementSuffix = "/>";

	# Table of MD5 sums for escaped characters
	EscapeTable = '\\`*_{}[]()#.!'.split(//).inject({}) do |table, char|
		hash = Digest::MD5::hexdigest(char)

		table[char] = {
 			:md5 => hash,
			:md5re => Regexp::new(hash),
			:re  => Regexp::new('\\\\' + Regexp::escape(char)),
		}
    table
  end

	# Convert tabs to spaces
	def detab(string, tabwidth = TabWidth)
		string.split("\n").collect { |line|
			line.gsub(/(.*?)\t/) do
				$1 + ' ' * (tabwidth - $1.length % tabwidth)
			end
		}.join("\n")
	end

end

require 'bluecloth/transform/blocks'
require 'bluecloth/transform/inline'
require 'bluecloth/transform/links'
require 'bluecloth/transform/util'
