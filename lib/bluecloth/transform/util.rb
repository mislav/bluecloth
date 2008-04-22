module BlueCloth::Transform
  
	### Escape any markdown characters in a copy of the given +str+ and return
	### it.
	def escape_md( str )
		str.
			gsub( /\*/, EscapeTable['*'][:md5] ).
			gsub( /_/,  EscapeTable['_'][:md5] )
	end

	# Matching constructs for tokenizing X/HTML
	HTMLCommentRegexp  = %r{ <! ( -- .*? -- \s* )+ > }mx
	XMLProcInstRegexp  = %r{ <\? .*? \?> }mx
	MetaTag = Regexp::union( HTMLCommentRegexp, XMLProcInstRegexp )

	HTMLTagOpenRegexp  = %r{ < [a-z/!$] [^<>]* }imx
	HTMLTagCloseRegexp = %r{ > }x
	HTMLTagPart = Regexp::union( HTMLTagOpenRegexp, HTMLTagCloseRegexp )

	### Break the HTML source in +str+ into a series of tokens and return
	### them. The tokens are just 2-element Array tuples with a type and the
	### actual content. If this function is called with a block, the type and
	### text parts of each token will be yielded to it one at a time as they are
	### extracted.
	def tokenize_html( str )
		depth = 0
		tokens = []
		@scanner.string = str.dup
		type, token = nil, nil

		until @scanner.eos?
			@log.debug "Scanning from %p" % @scanner.rest

			# Match comments and PIs without nesting
			if (( token = @scanner.scan(MetaTag) ))
				type = :tag

			# Do nested matching for HTML tags
			elsif (( token = @scanner.scan(HTMLTagOpenRegexp) ))
				tagstart = @scanner.pos
				@log.debug " Found the start of a plain tag at %d" % tagstart

				# Start the token with the opening angle
				depth = 1
				type = :tag

				# Scan the rest of the tag, allowing unlimited nested <>s. If
				# the scanner runs out of text before the tag is closed, raise
				# an error.
				while depth.nonzero?

					# Scan either an opener or a closer
					chunk = @scanner.scan( HTMLTagPart ) or
						raise "Malformed tag at character %d: %p" % 
							[ tagstart, token + @scanner.rest ]
						
					@log.debug "  Found another part of the tag at depth %d: %p" % [ depth, chunk ]

					token += chunk

					# If the last character of the token so far is a closing
					# angle bracket, decrement the depth. Otherwise increment
					# it for a nested tag.
					depth += ( token[-1, 1] == '>' ? -1 : 1 )
					@log.debug "  Depth is now #{depth}"
				end

			# Match text segments
			else
				@log.debug " Looking for a chunk of text"
				type = :text

				# Scan forward, always matching at least one character to move
				# the pointer beyond any non-tag '<'.
				token = @scanner.scan_until( /[^<]+/m )
			end

			@log.debug " type: %p, token: %p" % [ type, token ]

			# If a block is given, feed it one token at a time. Add the token to
			# the token list to be returned regardless.
			if block_given?
				yield( type, token )
			end
			tokens << [ type, token ]
		end

		return tokens
	end

	### Return a copy of +str+ with angle brackets and ampersands HTML-encoded.
	def encode_html( str )
		str.gsub( /&(?!#?[x]?(?:[0-9a-f]+|\w+);)/i, "&amp;" ).
			gsub( %r{<(?![a-z/?\$!])}i, "&lt;" )
	end

	### Return one level of line-leading tabs or spaces from a copy of +str+ and
	### return it.
	def outdent( str )
		str.gsub( /^(\t|[ ]{1,#{TabWidth}})/, '')
	end
  
end
