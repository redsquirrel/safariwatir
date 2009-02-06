= SafariWatir

* http://safariwatir.rubyforge.org
* http://rubyforge.org/mailman/listinfo/safariwatir-general
* http://twitter.com/SafariWatir

== DESCRIPTION:

We are putting Watir on Safari.
The original Watir (Web Application Testing in Ruby) project supports only IE on Windows.
This project aims at adding Watir support for Safari on the Mac.

== SYNOPSIS:

  require 'rubygems'
  require 'safariwatir'

  browser = Watir::Safari.new
  browser.goto("http://google.com")
  browser.text_field(:name, "q").set("obtiva")
  browser.button(:name, "btnI").click
  puts "FAILURE" unless browser.contains_text("software")

== INSTALL:

  [sudo] gem install safariwatir

 or

  git clone git://github.com/redsquirrel/safariwatir.git
  cd safariwatir
  gem build safariwatir.gemspec
  [sudo] gem install safariwatir
