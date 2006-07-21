Gem::Specification.new do |s|
	s.name = %q{safariwatir}
	s.version = "0.1.0"
	s.rubyforge_project = 'safariwatir'
	s.date = %q{2006-07-21}
	s.summary = %q{Automated testing tool for web applications.}
	s.description = %q{WATIR stands for "Web Application Testing in Ruby".  See WATIR project for more information.  This is simply a Safari-version of the original IE-only WATIR.}
	s.email = %q{dave.hoover@gmail.com}
	s.homepage = %q{http://safariwatir.rubyforge.org/}
	s.autorequire = %q{safari}
	s.authors = ["Dave Hoover"]
	s.require_paths = ['.']
	s.requirements = ["Mac OS X running Safari", %q{Some features require you to turn on "Enable access for assistive devices" in System Preferences > Universal Access}]
	s.files = ["safari.rb","safari_script.rb","safari/core_ext.rb","safari/scripter.rb","watir/exceptions.rb"]
end