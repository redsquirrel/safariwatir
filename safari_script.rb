require 'safari'

safari = Watir::Safari.start("http://google.com")
safari.text_field(:name, "q").set("pickaxe")
safari.button(:name, "btnG").click
safari.link(:text, "The Pragmatic Programmers, LLC: Programming Ruby").click
safari.link(:url, "http://www.pragmaticprogrammer.com/titles/ruby/code/index.html").click
safari.link(:text, "Catalog").click
safari.link(:text, "All Books").click
safari.link(:text, /Agile Retrospectives/).click
print "FAILURE" unless safari.contains_text("Dave Hoover")