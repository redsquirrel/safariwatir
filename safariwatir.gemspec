# -*- encoding: utf-8 -*-

Gem::Specification.new do |s|
  s.name = %q{safariwatir}
  s.version = "0.3.7"
  s.required_rubygems_version = Gem::Requirement.new(">= 1.2") if s.respond_to? :required_rubygems_version=
  s.authors = ["Dave Hoover", "Tom Copeland"]
  s.date = %q{2009-10-20}
  s.description = %q{WATIR stands for "Web Application Testing in Ruby".  See WATIR project for more information.  This is a Safari-version of the original IE-only WATIR.}
  s.email = %q{dave@obtiva.com}
  s.extra_rdoc_files = ["lib/safariwatir/core_ext.rb", "lib/safariwatir/scripter.rb", "lib/safariwatir.rb", "lib/watir/exceptions.rb", "README.rdoc"]
  s.files = ["lib/safariwatir/core_ext.rb", "lib/safariwatir/scripter.rb", "lib/safariwatir.rb", "lib/watir/exceptions.rb", "Rakefile", "README.rdoc", "safariwatir.gemspec", "safariwatir_example.rb"]
  s.has_rdoc = true
  s.homepage = %q{http://safariwatir.rubyforge.org/}
  s.rdoc_options = ["--line-numbers", "--inline-source", "--title", "Safariwatir", "--main", "README.rdoc"]
  s.require_paths = ["lib"]
  s.rubyforge_project = %q{safariwatir}
  s.rubygems_version = %q{1.3.1}
  s.summary = %q{Automated testing tool for web applications.}
  if s.respond_to? :specification_version then
    current_version = Gem::Specification::CURRENT_SPECIFICATION_VERSION
    s.specification_version = 2
    if Gem::Version.new(Gem::RubyGemsVersion) >= Gem::Version.new('1.2.0') then
      s.add_development_dependency(%q<rb-appscript>, [">= 0"])
    else
      s.add_dependency(%q<rb-appscript>, [">= 0"])
    end
  else
    s.add_dependency(%q<rb-appscript>, [">= 0"])
  end
end
