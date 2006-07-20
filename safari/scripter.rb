module Watir
  class AppleScripter

    @@timeout = 10
  
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
      
    def document_text
      execute(%|do Javascript "document.getElementsByTagName('BODY').item(0).innerText;" in document 1|)
    end
      
    def highlight(element, &block)
      execute(element.operate do
%|element.focus();        
element.originalColor = element.style.backgroundColor;
element.style.backgroundColor = 'yellow';|
      end)      

      @element = element
      instance_eval(&block)
      @element = nil

      execute(element.operate { %|element.style.backgroundColor = element.originalColor;| })
    end

    def select_option(option_how, option_what, element = @element)
      execute(element.operate do
%|for (var i = 0; i < element.options.length; i++) {
  if (element.options[i].#{option_how} == '#{option_what}') {
    element.options[i].selected = true;
  }
}|
      end)
    end
  
    def clear_text_input(element = @element)
      execute(element.operate { %|element.value = '';| })
    end
      
    def append_text_input(value, element = @element)
      execute(element.operate do 
%|element.value += '#{value}';
element.setSelectionRange(element.value.length, element.value.length);| 
      end)
    end

    # TODO need a better approach for "waiting"
    def click_element(element = @element)
      execute_and_wait(element.operate { %|element.click();| })
    end
  
    def click_link(element = @element)      
      click = find_link(element) do
%|var click = document.createEvent('HTMLEvents');
click.initEvent('click', true, true);
if (element.onclick) {
 	if (false != element.onclick(click)) {
		return element.href;
	}
} else {
	return element.href;
}|
      end
      execute_and_wait(%|set target to do JavaScript "#{click}" in document 1
set URL in document 1 to target|)
    end

    def operate_on_link(element, &block)
      %|do JavaScript "#{find_link(element, &block)}" in document 1|  
    end

    def find_link(element)
%|for (var i = 0; i < document.links.length; i++) {
  if (document.links[i].#{handle_match(element)}) {
    var element = document.links[i];
    #{yield}
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
  
    def operate_on_form_element(element)
%|do JavaScript "
var elements = document.getElementsByName('#{element.what}');
var element;
for (var i = 0; i < elements.length; i++) {
  if (elements[i].tagName != 'META') {
    #{handle_form_element_name_match(element)}
  }
}
#{yield}
" in document 1|
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
%|do JavaScript "
var element = document.getElementById('#{element.what}');
#{yield}" in document 1|  
    end

    def operate_on_label(element)
%|do JavaScript "
var elements = document.getElementsByTagName('LABEL');
var element;
for (var i = 0; i < elements.length; i++) {
  if (elements[i].textContent == '#{element.what}') {
    element = elements[i];
    #{yield}
    break;
  }
}
" in document 1|      
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

    def execute(script)      
     # puts script
`osascript <<SCRIPT
tell application "Safari"
	#{script}
end tell
SCRIPT`
    end

    # Must have "Enable access for assistive devices" checked in System Preferences > Universal Access
    def execute_system_events(script)      
`osascript <<SCRIPT
tell application "System Events" to tell process "Safari"  
	#{script}
end tell
SCRIPT`
    end

    def execute_and_wait(script)
      execute(%|
#{script}
delay 2
repeat with i from 1 to #{@@timeout}
  if (do JavaScript "document.readyState" in document 1) is "complete" then
    exit repeat
  else
    delay 1
  end if
end repeat|)
    end
  
    def ensure_window_ready
      execute(%|
activate
set document_list to every document
if length of document_list is 0 then
	make new document
end if|)      
    end
  end # class AppleScripter
end