BlueCloth
=========

<i><strong>Important:</strong> this repository is abandoned in favor of much
quicker implementations such as [bluecloth 2.0][2] and RDiscount.</i>

This is **a fork of BlueCloth 1.0.0** (2004/08/24) from its trunk. It's been
created to fix some of the outstanding bugs in its implementation.

The plan is to first clean up the messy test suite (using RSpec), make existing
tests pass (a lot of them fail right now) and, finally, add tests for annoying
bugs and making them pass also.

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

[1]: http://daringfireball.net/projects/markdown/
[2]: http://deveiate.org/projects/BlueCloth/
