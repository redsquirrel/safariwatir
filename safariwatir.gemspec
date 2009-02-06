Gem::Specification.new do |s|
	s.name = %q{safariwatir}
	s.version = "0.3.2"
	s.rubyforge_project = 'safariwatir'
	s.date = %q{2008-10-28}
	s.summary = %q{Automated testing tool for web applications.}
	s.description = %q{WATIR stands for "Web Application Testing in Ruby".  See WATIR project for more information.  This is a Safari-version of the original IE-only WATIR.}
	s.email = %q{dave@obtiva.com}
	s.homepage = %q{http://safariwatir.rubyforge.org/}
	s.authors = ["Dave Hoover"]
	s.require_paths = ['.']
	s.add_dependency('rb-appscript')
	s.requirements = ["Mac OS X running Safari", %q{Some features require you to turn on "Enable access for assistive devices" in System Preferences > Universal Access}]
	s.files = ["safariwatir.rb","safariwatir_script.rb","safariwatir/core_ext.rb","safariwatir/scripter.rb","safariwatir/exceptions.rb"]
	s.has_rdoc = true
end
