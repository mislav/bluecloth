module BlueCloth::Transform
  
	# Apply Markdown span transforms to a copy of the specified +str+ with the
	# given render state +rs+ and return it.
	def apply_span_transforms( str, rs )
		@log.debug "Applying span transforms to:\n  %p" % str

		str = transform_code_spans( str, rs )
		str = encode_html( str )
		str = transform_images( str, rs )
		str = transform_anchors( str, rs )
		str = transform_italic_and_bold( str, rs )

		# Hard breaks
		str.gsub!( / {2,}\n/, "<br#{EmptyElementSuffix}\n" )

		@log.debug "Done with span transforms:\n  %p" % str
		return str
	end
  
	# Pattern to match strong emphasis in Markdown text
	BoldRegexps = [
	  %r{ \b(\_\_) (\S|\S.*?\S) \1\b }x,
	  %r{ (\*\*) (\S|\S.*?\S) \1 }x
  ]
  
	# Pattern to match normal emphasis in Markdown text
	ItalicRegexps = [
	  %r{ (\*) (\S|\S.*?\S) \1 }x,
	  %r{ \b(_) (\S|\S.*?\S) \1\b }x
	]

	# Transform italic- and bold-encoded text in a copy of the specified +str+
	# and return it.
	def transform_italic_and_bold( str, rs )
		@log.debug " Transforming italic and bold"

		str.
			gsub( BoldRegexps[0], %{<strong>\\2</strong>} ).
			gsub( BoldRegexps[1], %{<strong>\\2</strong>} ).
			gsub( ItalicRegexps[0], %{<em>\\2</em>} ).
			gsub( ItalicRegexps[1], %{<em>\\2</em>} )
	end

	# Transform backticked spans into <code> spans.
	def transform_code_spans( str, rs )
		@log.debug " Transforming code spans"

		# Set up the string scanner and just return the string unless there's at
		# least one backtick.
		@scanner.string = str.dup
		unless @scanner.exist?( /`/ )
			@scanner.terminate
			@log.debug "No backticks found for code span in %p" % str
			return str
		end

		@log.debug "Transforming code spans in %p" % str

		# Build the transformed text anew
		text = ''

		# Scan to the end of the string
		until @scanner.eos?

			# Scan up to an opening backtick
			if pre = @scanner.scan_until( /.?(?=`)/m )
				text += pre
				@log.debug "Found backtick at %d after '...%s'" % [ @scanner.pos, text[-10, 10] ]

				# Make a pattern to find the end of the span
				opener = @scanner.scan( /`+/ )
				len = opener.length
				closer = Regexp::new( opener )
				@log.debug "Scanning for end of code span with %p" % closer

				# Scan until the end of the closing backtick sequence. Chop the
				# backticks off the resultant string, strip leading and trailing
				# whitespace, and encode any enitites contained in it.
				codespan = @scanner.scan_until( closer ) or
					raise FormatError::new( @scanner.rest[0,20],
						"No %p found before end" % opener )

				@log.debug "Found close of code span at %d: %p" % [ @scanner.pos - len, codespan ]
				codespan.slice!( -len, len )
				text += "<code>%s</code>" %
					encode_code( codespan.strip, rs )

			# If there's no more backticks, just append the rest of the string
			# and move the scan pointer to the end
			else
				text += @scanner.rest
				@scanner.terminate
			end
		end

		return text
	end

	# Next, handle inline images:  ![alt text](url "optional title")
	# Don't forget: encode * and _
	InlineImageRegexp = %r{
		(					# Whole match = $1
			!\[ (.*?) \]	# alt text = $2
		  \([ ]*
			<?(\S+?)>?		# source url = $3
		    [ ]*
			(?:				# 
			  (["'])		# quote char = $4
			  (.*?)			# title = $5
			  \4			# matching quote
			  [ ]*
			)?				# title is optional
		  \)
		)
	  }xs #"

	# Reference-style images
	ReferenceImageRegexp = %r{
		(					# Whole match = $1
			!\[ (.*?) \]	# Alt text = $2
			[ ]?			# Optional space
			(?:\n[ ]*)?		# One optional newline + spaces
			\[ (.*?) \]		# id = $3
		)
	  }xs

	# Turn image markup into image tags.
	def transform_images( str, rs )
		@log.debug " Transforming images" # % str

		# Handle reference-style labeled images: ![alt text][id]
		str.
			gsub( ReferenceImageRegexp ) {|match|
				whole, alt, linkid = $1, $2, $3.downcase
				@log.debug "Matched %p" % match
				res = nil
				alt.gsub!( /"/, '&quot;' )

				# for shortcut links like ![this][].
				linkid = alt.downcase if linkid.empty?

				if rs.urls.key?( linkid )
					url = escape_md( rs.urls[linkid] )
					@log.debug "Found url '%s' for linkid '%s' " % [ url, linkid ]

					# Build the tag
					result = %{<img src="%s" alt="%s"} % [ url, alt ]
					if rs.titles.key?( linkid )
						result += %{ title="%s"} % escape_md( rs.titles[linkid] )
					end
					result += EmptyElementSuffix

				else
					result = whole
				end

				@log.debug "Replacing %p with %p" % [ match, result ]
				result
			}.

			# Inline image style
			gsub( InlineImageRegexp ) {|match|
				@log.debug "Found inline image %p" % match
				whole, alt, title = $1, $2, $5
				url = escape_md( $3 )
				alt.gsub!( /"/, '&quot;' )

				# Build the tag
				result = %{<img src="%s" alt="%s"} % [ url, alt ]
				unless title.nil?
					title.gsub!( /"/, '&quot;' )
					result += %{ title="%s"} % escape_md( title )
				end
				result += EmptyElementSuffix

				@log.debug "Replacing %p with %p" % [ match, result ]
				result
			}
	end

	# Regexp to match special characters in a code block
	CodeEscapeRegexp = %r{( \* | _ | \{ | \} | \[ | \] | \\ )}x

	# Escape any characters special to HTML and encode any characters special
	# to Markdown in a copy of the given +str+ and return it.
	def encode_code( str, rs )
		str.gsub( %r{&}, '&amp;' ).
			gsub( %r{<}, '&lt;' ).
			gsub( %r{>}, '&gt;' ).
			gsub( CodeEscapeRegexp ) {|match| EscapeTable[match][:md5]}
	end
				
	# Escape special characters in the given +str+
	def escape_special_chars( str )
		@log.debug "  Escaping special characters"
		text = ''

		# The original Markdown source has something called '$tags_to_skip'
		# declared here, but it's never used, so I don't define it.

		tokenize_html( str ) {|token, str|
			@log.debug "   Adding %p token %p" % [ token, str ]
			case token

			# Within tags, encode * and _
			when :tag
				text += str.
					gsub( /\*/, EscapeTable['*'][:md5] ).
					gsub( /_/, EscapeTable['_'][:md5] )

			# Encode backslashed stuff in regular text
			when :text
				text += encode_backslash_escapes( str )
			else
				raise TypeError, "Unknown token type %p" % token
			end
		}

		@log.debug "  Text with escapes is now: %p" % text
		return text
	end

	# Swap escaped special characters in a copy of the given +str+ and return
	# it.
	def unescape_special_chars( str )
		EscapeTable.each {|char, hash|
			@log.debug "Unescaping escaped %p with %p" % [ char, hash[:md5re] ]
			str.gsub!( hash[:md5re], char )
		}

		return str
	end

	# Return a copy of the given +str+ with any backslashed special character
	# in it replaced with MD5 placeholders.
	def encode_backslash_escapes( str )
		# Make a copy with any double-escaped backslashes encoded
		text = str.gsub( /\\\\/, EscapeTable['\\'][:md5] )
		
		EscapeTable.each_pair {|char, esc|
			next if char == '\\'
			text.gsub!( esc[:re], esc[:md5] )
		}

		return text
	end
end
