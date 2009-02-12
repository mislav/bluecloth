# -*- encoding: utf-8 -*-

Gem::Specification.new do |s|
  s.name = %q{bluecloth}
  s.version = "1.1.0"

  s.required_rubygems_version = Gem::Requirement.new(">= 0") if s.respond_to? :required_rubygems_version=
  s.authors = ["Michael Granger", "Mislav Marohni\304\207"]
  s.date = %q{2009-02-12}
  s.description = %q{Markdown allows you to write using an easy-to-read, easy-to-write plain text format, then convert it to structurally valid XHTML (or HTML).}
  s.email = %q{mislav.marohnic@gmail.com}
  s.executables = ["bluecloth", "Markdown.pl"]
  s.files = ["README.markdown", "VERSION.yml", "bin/bluecloth", "bin/Markdown.pl", "lib/bluecloth", "lib/bluecloth/transform", "lib/bluecloth/transform/blocks.rb", "lib/bluecloth/transform/inline.rb", "lib/bluecloth/transform/links.rb", "lib/bluecloth/transform/util.rb", "lib/bluecloth/transform.rb", "lib/bluecloth.rb", "spec/api_spec.rb", "spec/bug_spec.rb", "spec/contrib_spec.rb", "spec/markdown_spec.rb", "spec/sample_loader.rb", "spec/samples", "spec/samples/all", "spec/samples/antsugar.txt", "spec/samples/code", "spec/samples/emphasis", "spec/samples/failing", "spec/samples/links", "spec/samples/lists", "spec/samples/ml-announce.txt", "spec/samples/re-overflow.txt", "spec/samples/re-overflow2.txt", "spec/samples/titles", "spec/spec.opts", "spec/spec_helper.rb"]
  s.has_rdoc = true
  s.homepage = %q{http://github.com/mislav/bluecloth}
  s.rdoc_options = ["--inline-source", "--charset=UTF-8"]
  s.require_paths = ["lib"]
  s.rubygems_version = %q{1.3.1}
  s.summary = %q{A Ruby implementation of Markdown}

  if s.respond_to? :specification_version then
    current_version = Gem::Specification::CURRENT_SPECIFICATION_VERSION
    s.specification_version = 2

    if Gem::Version.new(Gem::RubyGemsVersion) >= Gem::Version.new('1.2.0') then
    else
    end
  else
  end
end
