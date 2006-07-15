module Watir
  class AppleScripter

    @@timeout = 10
    
    def initialize
      execute(%|
activate
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
        
    def highlight(how, what)
      execute(operate_on_element(how, what) do
%|element.focus();        
element.originalColor = element.style.backgroundColor;
element.style.backgroundColor = 'yellow';|
      end)      

      @how, @what = how, what
      yield self
      @how, @what = nil, nil

      execute(operate_on_element(how, what) { %|element.style.backgroundColor = element.originalColor;| })
    end

    def clear_text_input(how = @how, what = @what)
      execute(operate_on_element(how, what) { %|element.value = '';| })
    end
        
    def append_text_input(value, how = @how, what = @what)
      execute(operate_on_element(how, what) do 
%|element.value += '#{value}';
element.setSelectionRange(element.value.length, element.value.length);| 
      end)
    end
    
    def click_element(how = @how, what = @what)
      execute(operate_on_element(how, what) { %|element.click();| })
    end
    
    def click_link(how = @how, what = @what)      
      click = find_link(how, what) do
%|var click = document.createEvent('HTMLEvents');
click.initEvent('click', true, true);
if (element.onclick) {
 	if (false != element.onclick(click)) {
		return element.href;
	}
} else {
	element.href;
}|
      end
      execute_and_wait(%|set target to do JavaScript "#{click}" in document 1
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

    def operate_on_element(how, what, &block)
      case how
        when :name:
          operate_on_form_element(what, &block)
        when :text:
          operate_on_link(how, what, &block)
        when :id:
          operate_by_id(what, &block)
      end      
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
	}" in document 1|
    end

    def operate_by_id(what)
%|do JavaScript "
var element = document.getElementById('#{what}');
#{yield}" in document 1|  
    end

    def operate_on_link(how, what, &block)
      %|do JavaScript "#{find_link(how, what, &block)}" in document 1|  
    end
    
    def find_link(how, what)
%|for (var i = 0; i < document.links.length; i++) {
  if (document.links[i].#{handle_link_match(how, what)}) {
    var element = document.links[i];
    #{yield}
  }
}|      
    end

    def handle_link_match(how, what)
      how = {:text => "text", :url => "href"}[how]
      case what
        when Regexp:
          %|#{how}.match(/#{what.source}/)|          
        when String:
          %|#{how} == '#{what}'|
      end
    end
  end # class AppleScripter
end