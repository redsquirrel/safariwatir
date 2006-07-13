require 'safari'

# TODO 
# Need to give feedback when browser dies or when elements are not found
# Be more attached to the Safari window, if a different window is selected, the AppleScript executes against it
# Highlight link and button clicks 

safari = Watir::Safari.start("http://google.com")
safari.text_field(:name, "q").set("pickaxe")
safari.button(:name, "btnG").click
safari.link(:text, "The Pragmatic Programmers, LLC: Programming Ruby").click
safari.link(:url, "http://www.pragmaticprogrammer.com/titles/ruby/code/index.html").click
safari.link(:text, "Catalog").click
safari.link(:text, "All Books").click
safari.link(:text, /Agile Retrospectives/).click
puts "FAILURE" unless safari.contains_text("Dave Hoover")
safari.close