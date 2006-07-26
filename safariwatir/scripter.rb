require File.dirname(__FILE__) + '/core_ext'
require File.dirname(__FILE__) + '/../watir/exceptions'

module Watir
  ELEMENT_NOT_FOUND = "__safari_watir_element_unfound__"
  FRAME_NOT_FOUND = "__safari_watir_frame_unfound__"
  NO_RESPONSE = "__safari_watir_no_response__"
  TABLE_CELL_NOT_FOUND = "__safari_watir_cell_unfound__"

  class JavaScripter
    def initialize(container = nil)
      @frame_container = container
    end
    
    def operate(locator, operation)
      wrap(%|
#{locator}
if (element) {
  #{operation}
} else {
  return '#{ELEMENT_NOT_FOUND}';
}|)
    end
    
    def wrap(script)
      if @frame_container
        # add in frame name when referencing parent or document
        script.gsub! "parent", "parent.#{@frame_container}"
        script.gsub! "document", "#{@frame_container}.document"
      end
      %|set response to do JavaScript "#{script}" in document 1|
    end
  end
  
  class AppleScripter
    include Watir::Exception
    
    attr_reader :js
    private :js
    
    TIMEOUT = 10
  
    def initialize(frame_control = nil)
      ensure_window_ready unless frame_control
      @js = frame_control || JavaScripter.new
    end
              
    def close
      execute(%|close document 1|)
    end

    def quit
      execute(%|quit|)
    end
  
    def navigate_to(url)
      execute_and_wait(%|set URL in document 1 to "#{url}"|)
    end

    def get_text_for(element = @element)
      execute(element.operate { %|return element.innerText| }, element)
    end

    def get_table_cell_text(element = @element)
      table_index = element.row.table.what - 1
      row_index = element.row.index - 1
      cell_index = element.index - 1
      
      execute(js.wrap(%|
var element;
try {
  element = document.getElementsByTagName('TABLE')[#{table_index}].rows[#{row_index}].cells[#{cell_index}];
} catch(error) {}
if (element == undefined) {
  return '#{TABLE_CELL_NOT_FOUND}';
}
return element.innerText;|))
    end

    def get_value_for(element = @element)
      execute(element.operate { %|return element.value;| }, element)
    end
      
    def document_text
      execute(js.wrap(%|document.getElementsByTagName('BODY').item(0).innerText;|))
    end
      
    def highlight(element, &block)
      execute(element.operate do
%|element.focus();        
element.originalColor = element.style.backgroundColor;
element.style.backgroundColor = 'yellow';|
      end, element)      

      @element = element
      instance_eval(&block)
      @element = nil

      execute_and_ignore(element.operate { %|element.style.backgroundColor = element.originalColor;| })
    end

    def select_option(option_how, option_what, element = @element)
      execute(element.operate do
%|for (var i = 0; i < element.options.length; i++) {
  if (element.options[i].#{option_how} == '#{option_what}') {
    element.options[i].selected = true;
  }
}|
      end, element)
    end
    
    def clear_text_input(element = @element)
      execute(element.operate { %|element.value = '';| }, element)
    end
      
    def append_text_input(value, element = @element)
      execute(element.operate do 
%|element.value += '#{value}';
element.setSelectionRange(element.value.length, element.value.length);| 
      end, element)
    end

    # TODO need a better approach for "waiting"
    def click_element(element = @element)
      execute_and_wait(element.operate { %|element.click();| })
    end
  
    def click_link(element = @element)      
      click = %/
function baseTarget() {
  var bases = document.getElementsByTagName('BASE');
  if (bases.length > 0) {
    return bases[0].target;
  } else {
    return;
  }
}
function undefinedTarget(target) {
  return target == undefined || target == '';
}
function topTarget(target) {
  return undefinedTarget(target) || target == '_top';
}
function nextLocation(element) {
  var target = element.target;
  if (undefinedTarget(target) && baseTarget()) {
    top[baseTarget()].location = element.href;
  } else if (topTarget(target)) {
    top.location = element.href;
  } else {
    top[target].location = element.href;    
  }
}
var click = document.createEvent('HTMLEvents');
click.initEvent('click', true, true);
if (element.onclick) {
 	if (false != element.onclick(click)) {
		nextLocation(element);
	}
} else {
	nextLocation(element);
}/
      execute_and_wait(js.operate(find_link(element), click))
    end

    def operate_on_link(element)
      js.operate(find_link(element), yield)
    end

    def find_link(element)
%|var element = undefined;
for (var i = 0; i < document.links.length; i++) {
  if (document.links[i].#{handle_match(element)}) {
    element = document.links[i];
    break;
  }
}|
    end
    private :find_link

    def handle_match(element)
      how = {:text => "text", :url => "href"}[element.how]
      case element.what
        when Regexp:
          %|#{how}.match(/#{element.what.source}/#{element.what.casefold? ? "i":nil})|          
        when String:
          %|#{how} == '#{element.what}'|
      end
    end
    private :handle_match
  
    def operate_by_input_value(element)
      js.operate(%|
var elements = document.getElementsByTagName('INPUT');
var element = undefined;
for (var i = 0; i < elements.length; i++) {
  if (elements[i].tagName != 'META') {
    if (elements[i].value == '#{element.what}') {
      element = elements[i];
      break;
    }
  }
}|, yield)
    end

    def operate_by_name(element)
      js.operate(%|
var elements = document.getElementsByName('#{element.what}');
var element = undefined;
for (var i = 0; i < elements.length; i++) {
  if (elements[i].tagName != 'META') {
    #{handle_form_element_name_match(element)}
  }
}|, yield)
    end
    
    def handle_form_element_name_match(element)
      element_capture = %|element = elements[i];break;|
      if element.by_value
%|if (elements[i].value == '#{element.by_value}') {
  #{element_capture}
}|        
      else
        element_capture
      end
    end
    private :handle_form_element_name_match

    def operate_by_id(element)
      js.operate("var element = document.getElementById('#{element.what}');", yield)
    end

    def operate_by_index(element)
      js.operate(%|var element = document.getElementsByTagName('#{element.tag}')[#{element.what}];|, yield)
    end

    def operate_on_label(element)
      js.operate(%|var elements = document.getElementsByTagName('LABEL');
var element = undefined;
for (var i = 0; i < elements.length; i++) {
  if (elements[i].innerText == '#{element.what}') {
    element = elements[i];
    break;
  }
}|, yield)
    end

    def submit_form(element)
      execute_and_wait(element.operate { %|element.submit();| })
    end

    def click_alert_ok
      execute_system_events(%|
tell window 1
	if button named "OK" exists then
		click button named "OK"
	end if
end tell|)
    end 

    def for_frame(frame)
      # verify the frame exists
      execute(js.wrap(%|
if (parent.#{frame.name} == undefined) {
  return '#{FRAME_NOT_FOUND}';
}|), frame)
      AppleScripter.new(JavaScripter.new("parent.#{frame.name}"))
    end

    def speak_value_of(element = @element)
      speak(get_value_for(element))
    end

    def speak_text_of(element = @element)
      speak(element.text)
    end

    def speak_options_for(element = @element)
      values = execute(element.operate do
%|var values = '';
for (var i = 0; i < element.options.length; i++) {
  if (element.options[i].selected == true) {
    values += ' ' + element.options[i].text;
  }
}
return values|
      end, element)
      speak(values)
    end    


    private

    def execute!(script)
# puts script
`osascript <<SCRIPT
tell application "Safari"
  set response to "#{NO_RESPONSE}"
	#{script}
	response
end tell
SCRIPT`.chomp
    end    
    
    def execute(script, element = nil)
      response = execute! script
      case response
        when NO_RESPONSE:
          nil
        when ELEMENT_NOT_FOUND:
          raise UnknownObjectException, "Unable to locate #{element.name} element with #{element.how} of #{element.what}." 
        when TABLE_CELL_NOT_FOUND:
          raise UnknownCellException, "Unable to locate a table cell." 
        when FRAME_NOT_FOUND:
          raise UnknownFrameException, "Unable to locate a frame with name #{element.name}." 
        else
          response
      end
    end
    
    def execute_and_ignore(script)
      execute! script
      nil
    end

    # Must have "Enable access for assistive devices" checked in System Preferences > Universal Access
    def execute_system_events(script)      
`osascript <<SCRIPT
tell application "System Events" to tell process "Safari"  
	#{script}
end tell
SCRIPT`
      nil
    end

    def execute_and_wait(script, element = nil)
      
      execute(%|
#{script}
delay 2
repeat with i from 1 to #{TIMEOUT}
  #{js.wrap("document.readyState")}
  if (response) is "complete" then
    exit repeat
  else
    delay 1
  end if
end repeat|, element)
    end
  
    def ensure_window_ready
      execute(%|
activate
set document_list to every document
if length of document_list is 0 then
	make new document
end if|)      
    end
    
    def speak(string)
`osascript <<SCRIPT
say "#{string.quote_safe}"
SCRIPT`
      nil
    end 
  end # class AppleScripter
end