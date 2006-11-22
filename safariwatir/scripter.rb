require File.dirname(__FILE__) + '/core_ext'
require File.dirname(__FILE__) + '/../watir/exceptions'
require 'appscript'

module Watir
  ELEMENT_NOT_FOUND = "__safari_watir_element_unfound__"
  FRAME_NOT_FOUND = "__safari_watir_frame_unfound__"
  NO_RESPONSE = "__safari_watir_no_response__"
  TABLE_CELL_NOT_FOUND = "__safari_watir_cell_unfound__"

  class JavaScripter    
    def operate(locator, operation)
%|#{locator}
if (element) {
  #{operation}
} else {
  return '#{ELEMENT_NOT_FOUND}';
}|
    end

    def wrap(script)
      # Needed because createEvent must be called on a document, and the JavaScripter sub-classes
      # do some transformations to lower-case "document" before we get here at runtime.
      script.gsub! "DOCUMENT", "document"
      script
    end
    
    def find_cell(cell)
      return %|getElementById('#{cell.what}')| if cell.how == :id
      raise RuntimeError, "Unable to use #{cell.how} to find TableCell" unless cell.row

      finder = 
      case cell.row.how
      when :id:
        %|getElementById('#{cell.row.what}')|
      when :index:
        case cell.row.table.how
        when :id
          %|getElementById('#{cell.row.table.what}').rows[#{cell.row.what-1}]|
        when :index:
          %|getElementsByTagName('TABLE')[#{cell.row.table.what-1}].rows[#{cell.row.what-1}]|
        else
          raise MissingWayOfFindingObjectException, "Table element does not support #{cell.row.table.how}"
        end
      else
        raise MissingWayOfFindingObjectException, "TableRow element does not support #{cell.row.how}"
      end
      
      finder + %|.cells[#{cell.what-1}]|
    end
  end

  class FrameJavaScripter < JavaScripter
    def initialize(frame)
      @page_container = "parent.#{frame.name}"
    end

    def wrap(script)
      # add in frame name when referencing parent or document
      script.gsub! "parent", "parent.#{@page_container}"
      script.gsub! "document", "#{@page_container}.document"
      super(script)
    end
  end

  class TableJavaScripter < JavaScripter
    def_init :cell
    
    def wrap(script)
      script.gsub! "document", "document." + find_cell(@cell)
      super(script)
    end
  end
  
  class AppleScripter
    include Watir::Exception
    
    attr_reader :js
    private :js
    
    TIMEOUT = 10
  
    def initialize(scripter = JavaScripter.new)
      @js = scripter
      @app = AS.app("Safari")
      @document = @app.documents[1]
    end
              
    def ensure_window_ready
      @app.activate
      @app.make(:new => :document) if @app.documents.get.size == 0
      @document = @app.documents[1]
    end

    def close
      @app.quit
    end
  
    def navigate_to(url)
      page_load do
        @document.URL.set(url)
      end
    end

    def current_location
      eval_js("window.location.href")
    end

    def get_text_for(element = @element)
      execute(element.operate { %|return element.innerText| }, element)
    end

    def operate_by_table_cell(element = @element)      
%|var element = document;
if (element == undefined) {
  return '#{TABLE_CELL_NOT_FOUND}';
}
#{yield}|
    end
        
    def get_value_for(element = @element)
      execute(element.operate { %|return element.value;| }, element)
    end
      
    def document_text
      execute(%|document.getElementsByTagName('BODY').item(0).innerText;|)
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

    def element_exists?(element = @element, &block)
      block ||= Proc.new {}
      execute(element.operate(&block), element)
      return true
      rescue UnknownObjectException
      return false
    end

    def select_option(element = @element)
      execute(element.operate do
        handle_option(element, %|element.options[i].selected = true;|)
      end, element)
    end
    
    def option_exists?(element = @element)
      element_exists?(element) { handle_option(element) }
    end
    
    def handle_option(select_list, selection = nil)
%|var option_found = false;
for (var i = 0; i < element.options.length; i++) {
  if (element.options[i].#{select_list.how} == '#{select_list.what}') {
    #{selection}
    option_found = true;
  }
}
if (!option_found) {
  return '#{ELEMENT_NOT_FOUND}';
}|      
    end
    private :handle_option
    
    def clear_text_input(element = @element)
      execute(element.operate { %|element.value = '';| }, element)
    end
      
    def append_text_input(value, element = @element)
      execute(element.operate do 
%|element.value += '#{value}';
element.setSelectionRange(element.value.length, element.value.length);| 
      end, element)
    end

    def click_element(element = @element)
      page_load do
        execute(element.operate { %|
if (element.click) {
  element.click();
} else {
  var event = DOCUMENT.createEvent('MouseEvents');
  event.initEvent('click', true, true);
  element.dispatchEvent(event);

  if (element.onclick) {
    var event = DOCUMENT.createEvent('HTMLEvents');
    event.initEvent('click', true, true);
    element.onclick(event);
  }
}| })
      end
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
var click = DOCUMENT.createEvent('HTMLEvents');
click.initEvent('click', true, true);
if (element.onclick) {
 	if (false != element.onclick(click)) {
		nextLocation(element);
	}
} else {
	nextLocation(element);
}/
      page_load do
        execute(js.operate(find_link(element), click))
      end
    end

    def operate_on_link(element)
      js.operate(find_link(element), yield)
    end

    def find_link(element)
      case element.how
      when :index:
%|var element = document.getElementsByTagName('A')[#{element.what-1}];|
      else
%|var element = undefined;
for (var i = 0; i < document.links.length; i++) {
  if (document.links[i].#{handle_match(element)}) {
    element = document.links[i];
    break;
  }
}|
      end
    end
    private :find_link

    def handle_match(element)
      how = {:text => "text", :url => "href"}[element.how]
      case element.what
        when Regexp:
          %|#{how}.match(/#{element.what.source}/#{element.what.casefold? ? "i":nil})|          
        when String:
          %|#{how} == '#{element.what}'|
        else
          raise RuntimeError, "Unable to locate #{element.name} with #{element.how}"
      end
    end
    private :handle_match
  
    def operate_by_input_value(element)
      js.operate(%|
var elements = document.getElementsByTagName('INPUT');
var element = undefined;
for (var i = 0; i < elements.length; i++) {
  if (elements[i].value == '#{element.what}') {
    element = elements[i];
    break;
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
      js.operate(%|var element = document.getElementsByTagName('#{element.tag}')[#{element.what-1}];|, yield)
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
      page_load do
        execute(element.operate { %|element.submit();| })
      end
    end

    def click_alert_ok
      execute_system_events(%|
tell window 1
	if button named "OK" exists then
		click button named "OK"
	end if
end tell|)
    end 

    def for_table(element)
      AppleScripter.new(TableJavaScripter.new(element))
    end

    def for_frame(element)
      # verify the frame exists
      execute(
%|if (parent.#{element.name} == undefined) {
  return '#{FRAME_NOT_FOUND}';
}|, element)
      AppleScripter.new(FrameJavaScripter.new(element))
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

    def speak(string)
`osascript <<SCRIPT
say "#{string.quote_safe}"
SCRIPT`
      nil
    end 


    private

    def execute(script, element = nil)
      response = eval_js(script)
      case response
        when NO_RESPONSE:
          nil
        when ELEMENT_NOT_FOUND:
          raise UnknownObjectException, "Unable to locate #{element.name} element with #{element.how} of #{element.what}" 
        when TABLE_CELL_NOT_FOUND:
          raise UnknownCellException, "Unable to locate a table cell with #{element.how} of #{element.what}"
        when FRAME_NOT_FOUND:
          raise UnknownFrameException, "Unable to locate a frame with name #{element.name}" 
        else
          response
      end
    end
    
    def execute_and_ignore(script)
      eval_js(script)
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
    
    def page_load
      last_location = current_location
      yield
      sleep 1
      return if last_location == current_location
      
      tries = 0
      TIMEOUT.times do |tries|
        if "complete" == eval_js("DOCUMENT.readyState")
          handle_client_redirect
          break
        else
          sleep 1
        end
      end
      raise "Unable to load page withing #{TIMEOUT} seconds" if tries == TIMEOUT-1
    end

    def handle_client_redirect
      no_redirect_flag = "proceed"
      redirect = eval_js(
%|var elements = DOCUMENT.getElementsByTagName('META');
for (var i = 0; i < elements.length; i++) {
	if ("refresh" == elements[i].httpEquiv && elements[i].content != undefined && elements[i].content.indexOf(";") != "-1") {
	  return elements[i].content;
	}
}
return "#{no_redirect_flag}"|)
      if redirect != no_redirect_flag
        time_til_redirect = redirect.split(";").first.to_i
        sleep time_til_redirect
      end
    end
    
    def eval_js(script)
      @app.do_JavaScript(js.wrap(script), :in => @document)      
    end
  end # class AppleScripter
end