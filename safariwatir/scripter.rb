module Watir
  NOT_FOUND = "__safari_watir_unfound__"
  NO_RESPONSE = "__safari_watir_no_response__"

  module JavaScripter
    def js_operation(locator, operation)
      js_wrapper(%|
#{locator}
if (element) {
  #{operation}
} else {
  return '#{NOT_FOUND}';
}|)
    end
    
    def js_wrapper(script)
      %|set response to do JavaScript "#{script}" in document 1|
    end
  end
  
  class AppleScripter
    include JavaScripter
    include Watir::Exception
    
    TIMEOUT = 10
  
    def initialize
      ensure_window_ready
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

    def speak_value_of(element = @element)
      speak(get_value_for(element))
    end

    def get_text_for(element = @element)
      execute(element.operate { %|return element.innerText| }, element)
    end

    def speak_text_of(element = @element)
      speak(element.text)
    end

    def get_value_for(element = @element)
      execute(element.operate { %|return element.value;| }, element)
    end
      
    def document_text
      execute(js_wrapper(%|document.getElementsByTagName('BODY').item(0).innerText;|))
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
      click = find_link(element) + %|
var click = document.createEvent('HTMLEvents');
click.initEvent('click', true, true);
if (element.onclick) {
 	if (false != element.onclick(click)) {
		return element.href;
	}
} else {
	return element.href;
}|
      execute_and_wait(%|set target to do JavaScript "#{click}" in document 1
set URL in document 1 to target|)
    end

    def operate_on_link(element)
      js_operation(find_link(element), yield)
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
          %|#{how}.match(/#{element.what.source}/)|          
        when String:
          %|#{how} == '#{element.what}'|
      end
    end
    private :handle_match
  
    def operate_by_input_value(element)
      js_operation(%|
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
      js_operation(%|
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
      js_operation("var element = document.getElementById('#{element.what}');", yield)
    end

    def operate_by_index(element)
      js_operation(%|var element = document.getElementsByTagName('#{element.tag}')[#{element.what}];|, yield)
    end

    def operate_on_label(element)
      js_operation(%|var elements = document.getElementsByTagName('LABEL');
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
        when NOT_FOUND:
          raise UnknownObjectException, "Unable to locate #{element.name} element with #{element.how} of #{element.what}." 
        when NO_RESPONSE:
          nil
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
  if (do JavaScript "document.readyState" in document 1) is "complete" then
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