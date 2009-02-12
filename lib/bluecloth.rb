# 
# Bluecloth is a Ruby implementation of Markdown, a text-to-HTML conversion
# tool.
# 
# == Synopsis
# 
#   doc = BlueCloth::new "
#     ## Test document ##
#
#     Just a simple test.
#   "
#
#   puts doc.to_html
# 
# == Authors
# 
# * Michael Granger <ged@FaerieMUD.org>
# 
# == Contributors
#
# * Martin Chase <stillflame@FaerieMUD.org> - Peer review, helpful suggestions
# * Florian Gross <flgr@ccan.de> - Filter options, suggestions
#
# == Copyright
#
# Original version:
#   Copyright (c) 2003-2004 John Gruber
#   <http://daringfireball.net/>  
#   All rights reserved.
#
# Ruby port:
#   Copyright (c) 2004 The FaerieMUD Consortium.
# 
# BlueCloth is free software; you can redistribute it and/or modify it under the
# terms of the GNU General Public License as published by the Free Software
# Foundation; either version 2 of the License, or (at your option) any later
# version.
# 
# BlueCloth is distributed in the hope that it will be useful, but WITHOUT ANY
# WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR
# A PARTICULAR PURPOSE.  See the GNU General Public License for more details.
# 
# == To-do
#
# * Refactor some of the larger uglier methods that have to do their own
#   brute-force scanning because of lack of Perl features in Ruby's Regexp
#   class. Alternately, could add a dependency on 'pcre' and use most Perl
#   regexps.
#
# * Put the StringScanner in the render state for thread-safety.

require 'logger'
require 'yaml'

# BlueCloth is a Ruby implementation of Markdown, a text-to-HTML conversion tool.
class BlueCloth
  
	version_hash = YAML::load(File.read(File.join(File.dirname(__FILE__), '..', 'VERSION.yml')))
	Version = [:major, :minor, :patch].map { |bit| version_hash[bit] }.join('.')

	# Create a new BlueCloth string.
	def initialize(content = "", *restrictions)
		@log = Logger::new( $deferr )
		@log.level = $DEBUG ?
			Logger::DEBUG :
			($VERBOSE ? Logger::INFO : Logger::WARN)
		@scanner = nil

		# Add any restrictions, and set the line-folding attribute to reflect
		# what happens by default.
		@filter_html = nil
		@filter_styles = nil
		restrictions.flatten.each {|r| __send__("#{r}=", true) }
		@fold_lines = true

    @content = content

		@log.debug "String is: %p" % self
	end

	# Filters for controlling what gets output for untrusted input. (But really,
	# you're filtering bad stuff out of untrusted input at submission-time via
	# untainting, aren't you?)
	attr_accessor :filter_html, :filter_styles

	# RedCloth-compatibility accessor. Line-folding is part of Markdown syntax,
	# so this isn't used by anything.
	attr_accessor :fold_lines

end

require 'bluecloth/transform'
BlueCloth.__send__ :include, BlueCloth::Transform
