module BlueCloth::Transform

	# Do block-level transforms on a copy of +str+ using the specified render
	# state +rs+ and return the results.
	def apply_block_transforms( str, rs )
		# Port: This was called '_runBlockGamut' in the original

		@log.debug "Applying block transforms to:\n  %p" % str
		text = transform_headers( str, rs )
		text = transform_hrules( text, rs )
		text = transform_lists( text, rs )
		text = transform_code_blocks( text, rs )
		text = transform_block_quotes( text, rs )
		text = transform_auto_links( text, rs )
		text = hide_html_blocks( text, rs )

		text = form_paragraphs( text, rs )

		@log.debug "Done with block transforms:\n  %p" % text
		return text
	end

	# The list of tags which are considered block-level constructs and an
	# alternation pattern suitable for use in regexps made from the list
	StrictBlockTags = %w[ p div h[1-6] blockquote pre table dl ol ul script noscript
		form fieldset iframe math ins del ]
	StrictTagPattern = StrictBlockTags.join('|')

	LooseBlockTags = StrictBlockTags - %w[ins del]
	LooseTagPattern = LooseBlockTags.join('|')

	# Nested blocks:
	# 	<div>
	# 		<div>
	# 		tags for inner block must be indented.
	# 		</div>
	# 	</div>
	StrictBlockRegex = %r{
		^						# Start of line
		<(#{StrictTagPattern})	# Start tag: \2
		\b						# word break
		(.*\n)*?				# Any number of lines, minimal match
		</\1>					# Matching end tag
		[ ]*					# trailing spaces
		$						# End of line or document
	  }ix

	# More-liberal block-matching
	LooseBlockRegex = %r{
		^						# Start of line
		<(#{LooseTagPattern})	# start tag: \2
		\b						# word break
		(.*\n)*?				# Any number of lines, minimal match
		.*</\1>					# Anything + Matching end tag
		[ ]*					# trailing spaces
		$						# End of line or document
	  }ix

	# Special case for <hr />.
	HruleBlockRegex = %r{
		(						# $1
			\A\n?				# Start of doc + optional \n
			|					# or
			.*\n\n				# anything + blank line
		)
		(						# save in $2
			[ ]*				# Any spaces
			<hr					# Tag open
			\b					# Word break
			([^<>])*?			# Attributes
			/?>					# Tag close
			$					# followed by a blank line or end of document
		)
	  }ix

	# Replace all blocks of HTML in +str+ that start in the left margin with
	# tokens.
	def hide_html_blocks( str, rs )
		@log.debug "Hiding HTML blocks in %p" % str
		
		# Tokenizer proc to pass to gsub
		tokenize = lambda { |match|
			key = Digest::MD5::hexdigest( match )
			rs.html_blocks[ key ] = match
			@log.debug "Replacing %p with %p" % [ match, key ]
			"\n\n#{key}\n\n"
		}

		rval = str.dup

		@log.debug "Finding blocks with the strict regex..."
		rval.gsub!( StrictBlockRegex, &tokenize )

		@log.debug "Finding blocks with the loose regex..."
		rval.gsub!( LooseBlockRegex, &tokenize )

		@log.debug "Finding hrules..."
		rval.gsub!( HruleBlockRegex ) {|match| $1 + tokenize[$2] }

		return rval
	end

	# Transform any Markdown-style horizontal rules in a copy of the specified
	# +str+ and return it.
	def transform_hrules( str, rs )
		@log.debug " Transforming horizontal rules"
		str.gsub( /^( ?[\-\*_] ?){3,}$/, "\n<hr#{EmptyElementSuffix}\n" )
	end

	# Patterns to match and transform lists
	ListMarkerOl = %r{\d+\.}
	ListMarkerUl = %r{[*+-]}
	ListMarkerAny = Regexp::union( ListMarkerOl, ListMarkerUl )

	ListRegexp = %r{
		  (?:
			^[ ]{0,#{TabWidth - 1}}		# Indent < tab width
			(#{ListMarkerAny})			# unordered or ordered ($1)
			[ ]+						# At least one space
		  )
		  (?m:.+?)						# item content (include newlines)
		  (?:
			  \z						# Either EOF
			|							#  or
			  \n{2,}					# Blank line...
			  (?=\S)					# ...followed by non-space
			  (?![ ]*					# ...but not another item
				(#{ListMarkerAny})
			   [ ]+)
		  )
	  }x

	# Transform Markdown-style lists in a copy of the specified +str+ and
	# return it.
	def transform_lists( str, rs )
		@log.debug " Transforming lists at %p" % (str[0,100] + '...')

		str.gsub( ListRegexp ) {|list|
			@log.debug "  Found list %p" % list
			bullet = $1
			list_type = (ListMarkerUl.match(bullet) ? "ul" : "ol")
			list.gsub!( /\n{2,}/, "\n\n\n" )

			%{<%s>\n%s</%s>\n} % [
				list_type,
				transform_list_items( list, rs ),
				list_type,
			]
		}
	end


	# Pattern for transforming list items
	ListItemRegexp = %r{
		(\n)?							# leading line = $1
		(^[ ]*)							# leading whitespace = $2
		(#{ListMarkerAny}) [ ]+			# list marker = $3
		((?m:.+?)						# list item text   = $4
		(\n{1,2}))
		(?= \n* (\z | \2 (#{ListMarkerAny}) [ ]+))
	  }x

	# Transform list items in a copy of the given +str+ and return it.
	def transform_list_items( str, rs )
		@log.debug " Transforming list items"

		# Trim trailing blank lines
		str = str.sub( /\n{2,}\z/, "\n" )

		str.gsub( ListItemRegexp ) {|line|
			@log.debug "  Found item line %p" % line
			leading_line, item = $1, $4

			if leading_line or /\n{2,}/.match( item )
				@log.debug "   Found leading line or item has a blank"
				item = apply_block_transforms( outdent(item), rs )
			else
				# Recursion for sub-lists
				@log.debug "   Recursing for sublist"
				item = transform_lists( outdent(item), rs ).chomp
				item = apply_span_transforms( item, rs )
			end

			%{<li>%s</li>\n} % item
		}
	end

	# Pattern for matching codeblocks
	CodeBlockRegexp = %r{
		(?:\n\n|\A)
		(									# $1 = the code block
		  (?:
			(?:[ ]{#{TabWidth}} | \t)		# a tab or tab-width of spaces
			.*\n+
		  )+
		)
		(^[ ]{0,#{TabWidth - 1}}\S|\Z)		# Lookahead for non-space at
											# line-start, or end of doc
	  }x

	# Transform Markdown-style codeblocks in a copy of the specified +str+ and
	# return it.
	def transform_code_blocks( str, rs )
		@log.debug " Transforming code blocks"

		str.gsub( CodeBlockRegexp ) {|block|
			codeblock = $1
			remainder = $2

			# Generate the codeblock
			%{\n\n<pre><code>%s\n</code></pre>\n\n%s} %
				[ encode_code( outdent(codeblock), rs ).rstrip, remainder ]
		}
	end

	# Pattern for matching Markdown blockquote blocks
	BlockQuoteRegexp = %r{
		  (?:
			^[ ]*>[ ]?		# '>' at the start of a line
			  .+\n			# rest of the first line
			(?:.+\n)*		# subsequent consecutive lines
			\n*				# blanks
		  )+
	  }x
	PreChunk = %r{ ( ^ \s* <pre> .+? </pre> ) }xm

	# Transform Markdown-style blockquotes in a copy of the specified +str+
	# and return it.
	def transform_block_quotes( str, rs )
		@log.debug " Transforming block quotes"

		str.gsub( BlockQuoteRegexp ) {|quote|
			@log.debug "Making blockquote from %p" % quote

			quote.gsub!( /^ *> ?/, '' ) # Trim one level of quoting 
			quote.gsub!( /^ +$/, '' )	# Trim whitespace-only lines

			indent = " " * TabWidth
			quoted = %{<blockquote>\n%s\n</blockquote>\n\n} %
				apply_block_transforms( quote, rs ).
				gsub( /^/, indent ).
				gsub( PreChunk ) {|m| m.gsub(/^#{indent}/o, '') }
			@log.debug "Blockquoted chunk is: %p" % quoted
			quoted
		}
	end

	# Regex for matching Setext-style headers
	SetextHeaderRegexp = %r{
		(.+)			# The title text ($1)
		\n
		([\-=])+		# Match a line of = or -. Save only one in $2.
		[ ]*\n+
	   }x

	# Regexp for matching ATX-style headers
	AtxHeaderRegexp = %r{
		^(\#{1,6})	# $1 = string of #'s
		[ ]*
		(.+?)		# $2 = Header text
		[ ]*
		\#*			# optional closing #'s (not counted)
		\n+
	  }x

	# Apply Markdown header transforms to a copy of the given +str+ amd render
	# state +rs+ and return the result.
	def transform_headers( str, rs )
		@log.debug " Transforming headers"

		# Setext-style headers:
		#	  Header 1
		#	  ========
		#  
		#	  Header 2
		#	  --------
		#
		str.
			gsub( SetextHeaderRegexp ) {|m|
				@log.debug "Found setext-style header"
				title, hdrchar = $1, $2
				title = apply_span_transforms( title, rs )

				case hdrchar
				when '='
					%[<h1>#{title}</h1>\n\n]
				when '-'
					%[<h2>#{title}</h2>\n\n]
				else
					title
				end
			}.

			gsub( AtxHeaderRegexp ) {|m|
				@log.debug "Found ATX-style header"
				hdrchars, title = $1, $2
				title = apply_span_transforms( title, rs )

				level = hdrchars.length
				%{<h%d>%s</h%d>\n\n} % [ level, title, level ]
			}
	end

	# Wrap all remaining paragraph-looking text in a copy of +str+ inside <p>
	# tags and return it.
	def form_paragraphs( str, rs )
		@log.debug " Forming paragraphs"
		grafs = str.
			sub( /\A\n+/, '' ).
			sub( /\n+\z/, '' ).
			split( /\n{2,}/ )

		rval = grafs.collect {|graf|

			# Unhashify HTML blocks if this is a placeholder
			if rs.html_blocks.key?( graf )
				rs.html_blocks[ graf ]

			# Otherwise, wrap in <p> tags
			else
				apply_span_transforms(graf, rs).
					sub( /^[ ]*/, '<p>' ) + '</p>'
			end
		}.join( "\n\n" )

		@log.debug " Formed paragraphs: %p" % rval
		return rval
	end


end
