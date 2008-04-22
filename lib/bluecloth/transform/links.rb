module BlueCloth::Transform
  
	# Link defs are in the form: ^[id]: url "optional title"
	LinkRegex = %r{
		^[ ]*\[(.+)\]:		# id = $1
		  [ ]*
		  \n?				# maybe *one* newline
		  [ ]*
		<?(\S+?)>?				# url = $2
		  [ ]*
		  \n?				# maybe one newline
		  [ ]*
		(?:
			# Titles are delimited by "quotes" or (parens).
			["(]
			(.+?)			# title = $3
			[")]			# Matching ) or "
			[ ]*
		)?	# title is optional
		(?:\n+|\Z)
	  }x

	# Strip link definitions from +str+, storing them in the given RenderState
	# +rs+.
	def strip_link_definitions( str, rs )
		str.gsub( LinkRegex ) {|match|
			id, url, title = $1, $2, $3

			rs.urls[ id.downcase ] = encode_html( url )
			unless title.nil?
				rs.titles[ id.downcase ] = title.gsub( /"/, "&quot;" )
			end
			""
		}
	end

	AutoAnchorURLRegexp = /<((https?|ftp):[^'">\s]+)>/
	AutoAnchorEmailRegexp = %r{
		<
		(
			[-.\w]+
			\@
			[-a-z0-9]+(\.[-a-z0-9]+)*\.[a-z]+
		)
		>
	  }xi

	# Transform URLs in a copy of the specified +str+ into links and return
	# it.
	def transform_auto_links( str, rs )
		@log.debug " Transforming auto-links"
		str.gsub( AutoAnchorURLRegexp, %{<a href="\\1">\\1</a>}).
			gsub( AutoAnchorEmailRegexp ) {|addr|
			encode_email_address( unescape_special_chars($1) )
		}
	end


	# Encoder functions to turn characters of an email address into encoded
	# entities.
	Encoders = [
		lambda {|char| "&#%03d;" % char},
		lambda {|char| "&#x%X;" % char},
		lambda {|char| char.chr },
	]

	# Transform a copy of the given email +addr+ into an escaped version safer
	# for posting publicly.
	def encode_email_address( addr )

		rval = ''
		("mailto:" + addr).each_byte {|b|
			case b
			when ?:
				rval += ":"
			when ?@
				rval += Encoders[ rand(2) ][ b ]
			else
				r = rand(100)
				rval += (
					r > 90 ? Encoders[2][ b ] :
					r < 45 ? Encoders[1][ b ] :
							 Encoders[0][ b ]
				)
			end
		}

		return %{<a href="%s">%s</a>} % [ rval, rval.sub(/.+?:/, '') ]
	end

	# Pattern to match the linkid part of an anchor tag for reference-style
	# links.
	RefLinkIdRegex = %r{
		[ ]?					# Optional leading space
		(?:\n[ ]*)?				# Optional newline + spaces
		\[
			(.*?)				# Id = $1
		\]
	  }x

	InlineLinkRegex = %r{
		\(						# Literal paren
			[ ]*				# Zero or more spaces
			<?(.+?)>?			# URI = $1
			[ ]*				# Zero or more spaces
			(?:					# 
				([\"\'])		# Opening quote char = $2
				(.*?)			# Title = $3
				\2				# Matching quote char
			)?					# Title is optional
		\)
	  }x

	# Apply Markdown anchor transforms to a copy of the specified +str+ with
	# the given render state +rs+ and return it.
	def transform_anchors( str, rs )
		@log.debug " Transforming anchors"
		@scanner.string = str.dup
		text = ''

		# Scan the whole string
		until @scanner.eos?
		
			if @scanner.scan( /\[/ )
				link = ''; linkid = ''
				depth = 1
				startpos = @scanner.pos
				@log.debug " Found a bracket-open at %d" % startpos

				# Scan the rest of the tag, allowing unlimited nested []s. If
				# the scanner runs out of text before the opening bracket is
				# closed, append the text and return (wasn't a valid anchor).
				while depth.nonzero?
					linktext = @scanner.scan_until( /\]|\[/ )

					if linktext
						@log.debug "  Found a bracket at depth %d: %p" % [ depth, linktext ]
						link += linktext

						# Decrement depth for each closing bracket
						depth += ( linktext[-1, 1] == ']' ? -1 : 1 )
						@log.debug "  Depth is now #{depth}"

					# If there's no more brackets, it must not be an anchor, so
					# just abort.
					else
						@log.debug "  Missing closing brace, assuming non-link."
						link += @scanner.rest
						@scanner.terminate
						return text + '[' + link
					end
				end
				link.slice!( -1 ) # Trim final ']'
				@log.debug " Found leading link %p" % link

				# Look for a reference-style second part
				if @scanner.scan( RefLinkIdRegex )
					linkid = @scanner[1]
					linkid = link.dup if linkid.empty?
					linkid.downcase!
					@log.debug "  Found a linkid: %p" % linkid

					# If there's a matching link in the link table, build an
					# anchor tag for it.
					if rs.urls.key?( linkid )
						@log.debug "   Found link key in the link table: %p" % rs.urls[linkid]
						url = escape_md( rs.urls[linkid] )

						text += %{<a href="#{url}"}
						if rs.titles.key?(linkid)
							text += %{ title="%s"} % escape_md( rs.titles[linkid] )
						end
						text += %{>#{link}</a>}

					# If the link referred to doesn't exist, just append the raw
					# source to the result
					else
						@log.debug "  Linkid %p not found in link table" % linkid
						@log.debug "  Appending original string instead: "
						@log.debug "%p" % @scanner.string[ startpos-1 .. @scanner.pos-1 ]
						text += @scanner.string[ startpos-1 .. @scanner.pos-1 ]
					end

				# ...or for an inline style second part
				elsif @scanner.scan( InlineLinkRegex )
					url = @scanner[1]
					title = @scanner[3]
					@log.debug "  Found an inline link to %p" % url

					text += %{<a href="%s"} % escape_md( url )
					if title
						title.gsub!( /"/, "&quot;" )
						text += %{ title="%s"} % escape_md( title )
					end
					text += %{>#{link}</a>}

				# No linkid part: just append the first part as-is.
				else
					@log.debug "No linkid, so no anchor. Appending literal text."
					text += @scanner.string[ startpos-1 .. @scanner.pos-1 ]
				end # if linkid

			# Plain text
			else
				@log.debug " Scanning to the next link from %p" % @scanner.rest
				text += @scanner.scan( /[^\[]+/ )
			end

		end # until @scanner.empty?

		return text
	end
  
end
