require 'rubygems'
require 'safariwatir'

# TODO 
#
# Looking up textareas, or any input element for that matter, by index
#
# Be more attached to the Safari window.
#    Currently, if a different window is selected, the AppleScript executes against it.
# Verify onclick is working for buttons and links
# TextFields should not respond to button method, etc.

# Unsupported Elements: Test that P/Div/Span/TD handle link, button, etc.,
#                       Javascript confirm [OK/CANCEL], Javascript prompt, Javascript popup windows

# Need to find a better way to distinguish between a submit button and a checkbox, re: page_load

# SAFARI ISSUES
# Labels are not clickable
# No known way to programatically click a <button> 
# Links with href="javascript:foo()"

safari = Watir::Safari.new

def safari.google_to_prag
  goto("http://google.com")
  text_field(:name, "q").set("pickaxe")
  button(:name, "btnG").click
  link(:text, /Programming Ruby/).click
  link(:url, "http://www.pragprog.com/titles/ruby/source_code").click
  link(:text, "All Categories").click
  link(:text, "All Titles").click
  link(:url, /retrospectives/).click
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
  select_list(:name, "url").select("VHS")
  select_list(:name, "url").select_value("search-alias=stripbooks")
  text_field(:name, "field-keywords").set("potter")
  button(:name, "Go").click
  puts "FAILURE amazon" unless contains_text("Deathly Hallows")
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
  puts "FAILURE google" unless contains_text("Training, Coaching, and Software Development")
end

def safari.reddit
  goto("http://reddit.com/")
  text_field(:name, "user").set("foo")
  password(:name, "passwd").set("bar")
  form(:index, 2).submit
  puts "FAILURE reddit" unless contains_text("foo") and contains_text("logout")  
end

def safari.colbert
  goto("http://www.colbertnation.com/cn/contact.php")
  text_field(:name, "formmessage").set("Beware the Bear")
  button(:value, "Send Email").click
  puts "FAILURE colbert" unless text_field(:name, "formmessage").verify_contains(/Enter message/)  
end

def safari.redsquirrel
  goto("http://redsquirrel.com/")
  begin
    text_field(:id, "not_there").set("imaginary")
    puts "FAILURE squirrel text no e"
  rescue Watir::UnknownObjectException => e
    puts "FAILURE squirrel text bad e" unless e.message =~ /not_there/
  end
  begin
    link(:text, "no_where").click
    puts "FAILURE squirrel link no e"
  rescue Watir::UnknownObjectException => e
    puts "FAILURE squirrel link bad e" unless e.message =~ /no_where/
  end
end

def safari.weinberg
  goto("http://www.geraldmweinberg.com/")
  puts "FAILURE weinberg menu" unless frame("menu").contains_text("Jerry Weinberg's Site")
  frame("menu").link(:text, "Books").click
  frame("menu").link(:text, /psychology/i).click
  puts "FAILURE weinberg content" unless frame("content").contains_text("Silver Anniversary")  
end

def safari.tables
  # Site Redesign, need to update test
  # goto("http://basecamphq.com/")
  # puts "FAILURE basecamp content" unless table(:index, 1)[1][2].text =~ /What is Basecamp\?/
  
  goto("http://www.jimthatcher.com/webcourse9.htm")
  puts "FAILURE thatcher" unless cell(:id, "c5").text == "subtotals"
  
  goto("http://amazon.com/")
  if contains_text("If you're not")
    link(:text, "click here").click
  end
    
  puts "FAILURE amazon tr" unless row(:id, "twotabtop")[2].text =~ /Your\s+Amazon\.com/
  row(:id, "twotabtop")[2].link(:index, 1).click
  puts "FAILURE amazon link" unless contains_text("personalized recommendations")
    
  goto("http://www.dreamweaverresources.com/tutorials/tableborder.htm")
  puts "FAILURE dreamweaver" unless table(:id, "titletable")[1][1].text =~ /CSS/
end

def safari.onchange
  goto("http://www.gr8cardeal.co.uk/?s=1")
  select_list(:name, "manufacturer").select_value("BMW")
  sleep 0.3 # There's an Ajax call here
  select_list(:name, "model").select_value("Z4 ROADSTER")
end

def safari.ruby_sponsor_images
  goto("http://mtnwestruby.org/")
  puts "FAILURE image obtiva" unless image(:src, "http://mtnwestruby.org/images/sponsors/obtiva_logo.png").exists?
  puts "FAILURE image thoughtworks" unless image(:src, /thoughtworks/).exists?
end

begin
  safari.google_to_prag
  safari.ala
  safari.amazon
  safari.google_advanced
  safari.reddit
  safari.colbert
  safari.redsquirrel
  safari.weinberg
  safari.tables
  safari.onchange
  safari.ruby_sponsor_images
end
