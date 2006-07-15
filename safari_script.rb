require 'safari'

# TODO 
# Need to give feedback when browser dies or when elements are not found
# Be more attached to the Safari window, if a different window is selected, the AppleScript executes against it
# Verify onclick is working for buttons and links

safari = Watir::Safari.new

def safari.prag_path
  goto("http://google.com")
  text_field(:name, "q").set("pickaxe")
  button(:name, "btnG").click
  link(:text, "The Pragmatic Programmers, LLC: Programming Ruby").click
  link(:url, "http://www.pragmaticprogrammer.com/titles/ruby/code/index.html").click
  link(:text, "Catalog").click
  link(:text, "All Books").click
  link(:text, /Agile Retrospectives/).click
  puts "FAILURE" unless contains_text("Dave Hoover")  
end

def safari.ala_path
  goto("http://alistapart.com/")
  text_field(:id, "search").set("grail")
  checkbox(:id, "incdisc").set
  button(:id, "submit").click
  puts "FAILURE" unless contains_text('Search Results for “grail”')  
end

safari.prag_path
safari.ala_path
safari.close