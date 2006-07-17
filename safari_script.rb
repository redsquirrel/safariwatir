require 'safari'

# TODO 
# Need to give feedback when browser dies or when elements are not found
# Be more attached to the Safari window, if a different window is selected, the AppleScript executes against it
# Verify onclick is working for buttons and links

# Radio, Textarea, Div, UL/OL, Span, Password
# Use dynamic properties for Javascript optimization
# Would using popen or open3 reduce the number of sub-processes?

safari = Watir::Safari.new

def safari.google_to_prag
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

def safari.ala
  goto("http://alistapart.com/")
  text_field(:id, "search").set("grail")
  checkbox(:id, "incdisc").set
  button(:id, "submit").click
  puts "FAILURE" unless contains_text('Search Results for “grail”')
end

def safari.amazon
  goto("http://amazon.com")
  select_list(:name, "url").select("Toys")
  select_list(:name, "url").select_value("index=software")
  text_field(:name, "keywords").set("Orion")
  image(:name, "Go").click
  puts "FAILURE" unless contains_text("Master of Orion (Original Release) (PC)")
end

safari.google_to_prag
safari.ala
safari.amazon

safari.close