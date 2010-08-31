# -*- encoding: utf-8 -*-

Gem::Specification.new do |s|
  s.name = %q{safariwatir}
  s.version = "0.3.9u"

  s.required_rubygems_version = Gem::Requirement.new(">= 1.2") if s.respond_to? :required_rubygems_version=
  s.authors = ["Dave Hoover"]
  s.date = %q{2010-08-31}
  s.description = %q{WATIR stands for "Web Application Testing in Ruby".  See WATIR project for more information.  This is a Safari-version of the original IE-only WATIR.}
  s.email = %q{dave@obtiva.com}
  s.extra_rdoc_files = ["README.rdoc", "lib/safariwatir.rb", "lib/safariwatir/core_ext.rb", "lib/safariwatir/element_attributes.rb", "lib/safariwatir/locators.rb", "lib/safariwatir/scripter.rb", "lib/watir/exceptions.rb"]
  s.files = ["History.txt", "README.rdoc", "Rakefile", "lib/safariwatir.rb", "lib/safariwatir/core_ext.rb", "lib/safariwatir/element_attributes.rb", "lib/safariwatir/locators.rb", "lib/safariwatir/scripter.rb", "lib/watir/exceptions.rb", "safariwatir.gemspec", "safariwatir_example.rb", "Manifest"]
  s.homepage = %q{http://wiki.openqa.org/display/WTR/SafariWatir}
  s.rdoc_options = ["--line-numbers", "--inline-source", "--title", "Safariwatir", "--main", "README.rdoc"]
  s.require_paths = ["lib"]
  s.rubyforge_project = %q{safariwatir}
  s.rubygems_version = %q{1.3.5}
  s.summary = %q{Automated testing tool for web applications.}

  if s.respond_to? :specification_version then
    current_version = Gem::Specification::CURRENT_SPECIFICATION_VERSION
    s.specification_version = 3

    if Gem::Version.new(Gem::RubyGemsVersion) >= Gem::Version.new('1.2.0') then
      s.add_runtime_dependency(%q<rb-appscript>, [">= 0"])
      s.add_development_dependency(%q<rb-appscript>, [">= 0"])
    else
      s.add_dependency(%q<rb-appscript>, [">= 0"])
      s.add_dependency(%q<rb-appscript>, [">= 0"])
    end
  else
    s.add_dependency(%q<rb-appscript>, [">= 0"])
    s.add_dependency(%q<rb-appscript>, [">= 0"])
  end
end
