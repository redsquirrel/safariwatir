require 'safari'

# TODO 
# Need to give feedback when browser dies or when elements are not found
# Be more attached to the Safari window, if a different window is selected, the AppleScript executes against it
# Verify onclick is working for buttons and links

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

#safari.google_to_prag
#safari.ala

safari.goto("http://amazon.com")
safari.select_list(:name, "url").select("Toys")
safari.select_list(:name, "url").select_value("index=software")
safari.text_field(:name, "keywords").set("Orion")
# safari.image(:name, "Go").click
#puts "FAILURE" unless safari.contains_text("Master of Orion (Original Release) (PC)")
#safari.close