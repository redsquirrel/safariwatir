module Watir
  class AppleScripter

    @@timeout = 10
    
    def initialize
      execute(%|
set document_list to every document
if length of document_list is 0 then
	make new document
end if|)
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
        
    def highlight(name)
      execute(operate_on_form_element(name) { %|
element.focus();        
element.originalColor = element.style.backgroundColor;
element.style.backgroundColor = 'yellow';
| })      
      
      yield self
      
      execute(operate_on_form_element(name) { %|element.style.backgroundColor = element.originalColor;| })
    end

    def clear_text_input(name)
      execute(operate_on_form_element(name) { %|element.value = '';| })
    end
        
    def append_text_input(name, value)
      execute(operate_on_form_element(name) { %|
element.value += '#{value}';
element.setSelectionRange(element.value.length, element.value.length);| })
    end
    
    def click_button(name)
      execute(operate_on_form_element(name) { %|element.click();| })
    end
    
    def click_link_with_text(what)
      execute_and_wait(%|
set target to do JavaScript "
	// HANDLE WHEN ELEMENT NOT FOUND
  #{find_link_by('text', what)}
  #{click_link}" in document 1
set URL in document 1 to target|)
    end
    
    def click_link_with_url(what)      
      execute_and_wait(%|
set target to do JavaScript "
	// HANDLE WHEN ELEMENT NOT FOUND
  #{find_link_by('href', what)}
  #{click_link}" in document 1
set URL in document 1 to target|)
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
`osascript <<SCRIPT
tell application "Safari"
  activate
	#{script}
end tell
SCRIPT`
    end

    # Must have "Enable access for assistive devices" checked in System Preferences > Universal Access
    def execute_system_events(script)      
`osascript <<SCRIPT
tell application "System Events" to tell process "Safari"
  activate
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

    def operate_on_form_element(name)
%|do JavaScript "
	for (var i = 0; i < document.forms.length; i++) {
		for (var j = 0; j < document.forms[i].elements.length; j++) {
			var element = document.forms[i].elements[j];
			if (element.name == '#{name}') {            
			  #{yield}
		  }
		}
	}
" in document 1|
    end

    def find_link_by(how, what)
%|var element;
for (var i = 0; i < document.links.length; i++) {
  if (document.links[i].#{handle_match(how, what)}) {
    element = document.links[i];  
  }
}|
    end
    
    def handle_match(how, what)
      case what
        when Regexp:
          %|#{how}.match(/#{what.source}/)|          
        when String:
          %|#{how} == '#{what}'|
        end
    end

    def click_link
%|
var click = document.createEvent('HTMLEvents');
click.initEvent('click', true, true);
if (element.onclick) {
 	if (false != element.onclick(click)) {
		return element.href;
	}
} else {
	element.href;
}|
    end
  end # class AppleScripter
end