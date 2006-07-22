require 'safari'

# TODO 
# Need to give feedback when browser dies or when elements are not found
# Be more attached to the Safari window, if a different window is selected, the AppleScript executes against it
# Verify onclick is working for buttons and links

# Unsupported Elements: Textarea, Div, UL/OL, Span
# Use dynamic properties for Javascript optimization?
# Will I need to push more functionality into AppleScript to speed things up?
# Angrez is looking into the Ruby/AppleScript binding
# Watir Rails Plugin needed

# SAFARI ISSUES
# Labels are not clickable
# No known way to programatically click a <button> 
# Links with href="javascript:foo()"

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
  puts "FAILURE prag" unless contains_text("Dave Hoover")  
end

def safari.ala
  goto("http://alistapart.com/")
  text_field(:id, "search").set("grail")
  checkbox(:id, "incdisc").set
  button(:id, "submit").click
  puts "FAILURE ala" unless contains_text('Search Results for “grail”')
end

def safari.amazon
  goto("http://amazon.com")
  select_list(:name, "url").select("Toys")
  select_list(:name, "url").select_value("index=software")
  text_field(:name, "keywords").set("Orion")
  image(:name, "Go").click
  puts "FAILURE amazon" unless contains_text("Master of Orion (Original Release) (PC)")
end

def safari.google_advanced
  goto("http://www.google.com/advanced_search")
  radio(:name, "safe", "active").set
  radio(:name, "safe", "images").set
  # Safari doesn't support label clicking ... perhaps I should raise an Exception
  label(:text, "No filtering").click
  radio(:id, "ss").set
  text_field(:name, "as_q").set("obtiva")
  button(:name, "btnG").click
  puts "FAILURE google" unless contains_text("RailsConf Facebook")
end

def safari.reddit
  goto("http://reddit.com/")
  text_field(:name, "user").set("foo")
  password(:name, "passwd").set("bar")
  form(:index, 1).submit
  puts "FAILURE reddit" unless contains_text("foo") and contains_text("logout")  
end

safari.google_to_prag
safari.ala
safari.amazon
safari.google_advanced
safari.reddit

safari.close