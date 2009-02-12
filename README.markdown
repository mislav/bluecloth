BlueCloth
=========

<i>Forked by <a href="http://github.com/mislav"><strong>Mislav</strong></a> on April 9, 2008</i>

This is **a fork of BlueCloth 1.0.0** (2004/08/24) from [its
trunk](svn://deveiate.org/BlueCloth/trunk). It's been created to finally fix
some of the outstanding bugs in its abandoned implementation.

The plan is to first clean up the messy test suite (using RSpec), make existing
tests pass (a lot of them fail right now) and, finally, add tests for annoying
bugs and making them pass also. Feel free to help out.

I also want to break down its implementation not to be entirely contained in
one file ("lib/bluecloth.rb") anymore. Together with a nicer test suite, that
will probably make it easier to maintain.


About
-----

Original version by John Gruber <http://daringfireball.net/>.  
Ruby port by Michael Granger <http://www.deveiate.org/>.

BlueCloth is a Ruby implementation of [Markdown][1], a text-to-HTML conversion
tool for web writers. To quote from the project page: Markdown allows you to
write using an easy-to-read, easy-to-write plain text format, then convert it to
structurally valid XHTML (or HTML).

It borrows a naming convention and several helpings of interface from
[Redcloth][2], [Why the Lucky Stiff][3]'s processor for a similar text-to-HTML
conversion syntax called [Textile][4].


Installation
------------

You can install this module either by running the included `install.rb` script,
or by simply copying `lib/bluecloth.rb` to a directory in your load path.


Dependencies
------------

BlueCloth uses the `StringScanner` class from the `strscan` library, which comes
with Ruby 1.8.x and later or may be downloaded from the RAA for earlier
versions, and the `logger` library, which is also included in 1.8.x and later.


Example Usage
-------------

The BlueCloth class is a subclass of Ruby's String, and can be used thusly:

    bc = BlueCloth::new( str )
    puts bc.to_html

This `README` file is an example of Markdown syntax. The sample program
`bluecloth` in the `bin/` directory can be used to convert this (or any other)
file with Markdown syntax into HTML:

    $ bin/bluecloth README > README.html


Acknowledgements
----------------

This library is a port of the canonical Perl one, and so owes most of its
functionality to its author, John Gruber. The bugs in this code are most
certainly an artifact of my porting it and not an artifact of the excellent code
from which it is derived.

It also, as mentioned before, borrows its API liberally from RedCloth, both for
compatibility's sake, and because I think Why's code is beautiful. His excellent
code and peerless prose have been an inspiration to me, and this module is
intended as the sincerest flattery.

Also contributing to any success this module may enjoy are those among my peers
who have taken the time to help out, either by submitting patches, testing, or
offering suggestions and review:

* Martin Chase <stillflame@FaerieMUD.org>
* Florian Gross <flgr@ccan.de>


[1]: http://daringfireball.net/projects/markdown/
[2]: http://www.whytheluckystiff.net/ruby/redcloth/
[3]: http://www.whytheluckystiff.net/
[4]: http://www.textism.com/tools/textile/
