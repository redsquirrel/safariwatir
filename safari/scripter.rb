module Watir
  class AppleScripter

    @@timeout = 10
    
    def navigate_to(url)
      execute_and_wait(%|set URL in document 1 to "#{url}"|)
    end
        
    def document_text
      execute(%|do Javascript "document.getElementsByTagName('BODY').item(0).innerText;" in document 1|)
    end
        
    def highlight(name)
      execute(operate_on_form_element(name) { %|element.originalColor = element.style.backgroundColor;element.style.backgroundColor = 'yellow';| })      
      
      yield self
      
      execute(operate_on_form_element(name) { %|element.style.backgroundColor = element.originalColor;| })
    end

    def clear_text_input(name)
      execute(operate_on_form_element(name) { %|element.value = '';| })
    end
        
    def append_text_input(name, value)
      execute(operate_on_form_element(name) { %|element.value += '#{value}';| })
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

    private

    def execute(script)
`osascript <<SCRIPT
tell application "Safari"
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
}      
|
    end
  end # class AppleScripter
end