require File.dirname(__FILE__) + '/core_ext'
require File.dirname(__FILE__) + '/../watir/exceptions'
require 'appscript'

module Watir # :nodoc:
  ELEMENT_NOT_FOUND = "__safari_watir_element_unfound__"
  FRAME_NOT_FOUND = "__safari_watir_frame_unfound__"
  NO_RESPONSE = "__safari_watir_no_response__"
  TABLE_CELL_NOT_FOUND = "__safari_watir_cell_unfound__"
  EXTRA_ACTION_SUCCESS = "__safari_watir_extra_action__"
  
  JS_LIBRARY = <<JSCODE
/* Library functions */

var ButtonMatcher = function() {
  this.match = function(ele) {
    if (ele.tagName == "BUTTON") { 
      return(true);
    }

    if (ele.tagName == 'INPUT') {
      return(["submit", "button", "reset"].indexOf(ele.type) != -1);
    }

    return(false);
  }
}


var ExactValueMatcher = function(exactVal) {
  this.match = function (val) {
    return(val == exactVal);
  }
}

var RegexValueMatcher = function(regEx) {
  this.match = function (val) {
    return(regEx.test(val));
  }
}

function dispatchOnChange(scope, element) {
  var event = scope.createEvent('HTMLEvents');
  event.initEvent('change', true, true);  
  element.dispatchEvent(event);
}

function findByXPath(dscope, scope, expr) {
  var result = dscope.evaluate(expr, scope, null, XPathResult.FIRST_ORDERED_NODE_TYPE, null);
  return(result ? result.singleNodeValue : null );
}

function filterToMethodValue(found_tags, m_name, m_value) {
  var result_array = [];

  for (var i = 0; i < found_tags.length; i++) {
    if (m_value.match(found_tags[i][m_name])) {
      result_array.push(found_tags[i]);
    }
  }
  return(result_array);
}

function filterToAttributeValue(found_tags, attr_name, attr_value) {
  var result_array = [];

  for (var i = 0; i < found_tags.length; i++) {
    if (attr_value.match(found_tags[i].getAttribute(attr_name))) {
      result_array.push(found_tags[i]);
    }
  }
  return(result_array);
}

function filterToTagNames(found_tags, tags) {
  var result_array = [];

  for (var i = 0; i < found_tags.length; i++) {
    if (found_tags[i].tagName != 'META' && tags.indexOf(found_tags[i].tagName) != -1) {
      result_array.push(found_tags[i]);
    }
  }
  return(result_array);
}

function findByClassName(scope, cname, tags) {
  var found_tags = scope.getElementsByClassName(cname);
  return( filterToTagNames(tags) );
}

function findInputByMethodValue(scope, input_type, attribute, value) {
  var found_tags = findInputsByType(scope, input_type);
  return( filterToMethodValue(found_tags, attribute, value) );
}

function findInputByAttributeValue(scope, input_type, attribute, value) {
  var found_tags = findInputsByType(scope, input_type);
  return( filterToAttributeValue(found_tags, attribute, value) );
}

function findByMethodValue(scope, names, attribute, value) {
  var found_tags = findByTagNames(scope, names);
  return( filterToMethodValue(found_tags, attribute, value) );
}

function findByAttributeValue(scope, names, attribute, value) {
  var found_tags = findByTagNames(scope, names);
  return( filterToAttributeValue(found_tags, attribute, value) );
}

function findAllMatching(scope, ele_matcher) {
  var result_array = [];
  var found_tags = scope.getElementsByTagName('*');

  for (var i = 0; i < found_tags.length; i++) {
    if (ele_matcher.match(found_tags[i])) {
      result_array.push(found_tags[i]);
    }
  }
  return(result_array);
}

function findInputsByType(scope, input_type) {
  var result_array = [];
  var found_tags = scope.getElementsByTagName("input");

  for (var i = 0; i < found_tags.length; i++) {
    if (found_tags[i].type == input_type) {
      result_array.push(found_tags[i]);
    }
  }
  return(result_array);
}

function findByTagNames(scope, names) {
  var result_array = [];
  var found_tags = null;

  for (var i = 0; i < names.length; i++) {
    found_tags = scope.getElementsByTagName(names[i]);
    for (var j = 0; j < found_tags.length; j++) {
      result_array.push(found_tags[j]);
    }
  }
  return(result_array);
}

/* Action Code */
JSCODE

  class JavaScripter # :nodoc:
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
      
# Needed because I would like to blindly use return statements, but Safari 3 enforces
# the ECMAScript standard that return statements are only valid within functions.
%|#{JS_LIBRARY}
(function() {
  #{script}
})()|
    end
    
    def find_cell(cell)
      return %|getElementById('#{cell.what}')| if cell.how == :id
      raise RuntimeError, "Unable to use #{cell.how} to find TableCell" unless cell.row

      finder = 
      case cell.row.how
      when :id
        %|getElementById('#{cell.row.what}')|
      when :index
        case cell.row.table.how
        when :id
          %|getElementById('#{cell.row.table.what}').rows[#{cell.row.what-1}]|
        when :index
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

  class TableJavaScripter < JavaScripter # :nodoc:
    def_init :cell
    
    def wrap(script)
      script.gsub! "document", "document." + find_cell(@cell)
      super(script)
    end
  end
  
  class AppleScripter # :nodoc:
    include Watir::Exception
    
    attr_reader :js
    attr_accessor :typing_lag
    private :js
    
    TIMEOUT = 10

    def initialize(scripter = JavaScripter.new, opts={})
      @js = scripter
      @appname = opts[:appname] || "Safari"
      @app = Appscript.app(@appname)
      @document = @app.documents[1]
      @typing_lag = 0.08
    end
              
    def ensure_window_ready
      @app.activate
      @app.make(:new => :document) if @app.documents.get.size == 0
      @document = @app.documents[1]
    end
    
    def url
        @document.URL.get
    end
    
    def hide
      # because applescript is stupid and annoying you have
      # to get all the processes from System Events, grab
      # the right one for this instance and then set visible
      # of it to false.
      se = Appscript.app("System Events")
      safari = se.processes.get.select do |app|
        app.name.get == @appname
      end.first
      safari.visible.set(false)
    end
    
    def close
      @app.quit
    end
  
    def navigate_to(url, &extra_action)
      page_load(extra_action) do
        @document.URL.set(url)
      end
    end
    
    def reload
      execute(%|window.location.reload()|)
    end

    def get_text_for(element = @element)
      execute(element.operate { %|return element.innerText| }, element)
    end

    def get_html_for(element = @element)
      execute(element.operate { %|return element.innerHTML| }, element)
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

    def get_attribute(name, element = @element)
      execute(element.operate { %|return element.getAttribute('#{name}')| }, element)
    end

    def get_method_value(name, element = @element)
      execute(element.operate { %|return element.#{name}| }, element)
    end
    
      
    def document_text(element)
      execute(%|return #{element.locator}.getElementsByTagName('BODY').item(0).innerText;|)
    end

    def document_html
      execute(%|return document.all[0].outerHTML;|)
    end

    def document_title
      execute(%|return document.title;|)
    end
  
    def focus(element)
      execute(element.operate { %|element.focus();| }, element)
    end

    def blur(element)
      execute(element.operate { %|element.blur();| }, element)
    end
      
    def highlight(element, &block)
      execute(element.operate do
%|element.originalColor = element.style.backgroundColor;
element.style.backgroundColor = 'yellow';|
      end, element)      

      @element = element
      instance_eval(&block)
      @element = nil

      execute_and_ignore(element.operate { %|element.style.backgroundColor = element.originalColor;| })
    end

    def element_exists?(element = @element, &block)
      response = eval_js(element.operate do
<<JSCODE
if (element == undefined || element == null) {
  return(false);
}
return(true);
JSCODE
end)
    case response
    when ELEMENT_NOT_FOUND
      return false
    else
      return response
    end
    end

    def select_option(element = @element)
      execute(element.operate do %|
  var other_options = element.parentNode.options;
  for (var i = 0; i < other_options.length; i++) {
    other_options[i].selected = undefined;
  }
  element.selected = "selected";
  element.parentNode.selectedIndex = element.index;
  dispatchOnChange(#{element.document_locator}, element);
  dispatchOnChange(#{element.document_locator}, element.parentNode);
|
      end, element)
    end
    
    def option_exists?(element = @element)
      element_exists?(element) { handle_option(element) }
    end
    
    def handle_option(select_list)
%|var option_found = false;
for (var i = 0; i < element.options.length; i++) {
  if (element.options[i].#{select_list.how} == '#{select_list.what}') {
    option_found = true;
  }
}
if (!option_found) {
  return '#{ELEMENT_NOT_FOUND}';
}|      
    end
    private :handle_option

    def option_selected?(element = @element)
      element_exists?(element) { handle_selected(element) == "true" }
    end

    def handle_selected(select_list)
%|var selected = false;
for (var i = 0; i < element.options.length; i++) {
  if (element.options[i].#{select_list.how} == '#{select_list.what}' && element.options[i].selected) {
    selected = true;
  }
}
return selected;|      
    end
    private :handle_option
    
    def clear_text_input(element = @element)
      execute(element.operate { %|element.value = '';| }, element)
    end
      
    def append_text_input(value, element = @element)
      sleep typing_lag
      execute(element.operate do 
%|element.value += '#{value}';
dispatchOnChange(#{element.document_locator}, element);
element.setSelectionRange(element.value.length, element.value.length);
| 
      end, element)
    end

    def set_file_field(element, value)
      file_base_name = File.basename(value)
      click_element(element)
      sleep 0.4
      se = Appscript.app("System Events")
      open_popup = se.processes["Safari"].windows[1].sheets[1]
      choose_button = open_popup.buttons[1]
      search_field = open_popup.groups[1].text_fields[1]
      search_by_file_name = open_popup.groups[1].splitter_groups[1].radio_groups[1].checkboxes[6]
      sr_outline = open_popup.groups[1].splitter_groups[1].scroll_areas[2].outlines[1]
      confirm_search_action = search_field.actions[2].get    
      search_field.value.set(file_base_name)
      search_field.perform(confirm_search_action)
      sleep 2
      search_by_file_name.click
      sleep 1
      sr_outline.rows[1].select
      choose_button.click
    end

    def click_element(element = @element)
      page_load do
# Not sure if these events should be either/or. But if you have an image with an onclick, it fires twice without the else clause.
        execute(element.operate { %|
if (element.click) {
  element.click();
} else {
  if (element.onclick) {
    var event = DOCUMENT.createEvent('HTMLEvents');
    event.initEvent('click', true, true);
    element.onclick(event);
  } else {
    var event = DOCUMENT.createEvent('MouseEvents');
    event.initEvent('click', true, true);
    element.dispatchEvent(event);    
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

    def click_link_jquery(element = @element)      
      click = %/
$(element).trigger('click');
/
      page_load do
        execute(js.operate(find_link(element), click))
      end
    end

    def operate_on_link(element)
      js.operate(find_link(element), yield)
    end

    # This needs to take XPath into account now?
    def find_link(element)
      case element.how
      when :index
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

    def handle_match(element, how = nil)
      how = {:text => "text", :url => "href", :id => "id"}[element.how] unless how
      case element.what
        when Regexp
          %|#{how}.match(/#{element.what.source}/#{element.what.casefold? ? "i":nil})|          
        when String
          %|#{how} == '#{element.what}'|
        else
          raise RuntimeError, "Unable to locate #{element.element_name} with #{element.how}"
      end
    end
    private :handle_match
  
    # Contributed by Kyle Campos
    def checkbox_is_checked?(element = @element)
      execute(element.operate { %|return element.checked;| }, element)
    end
    
    def element_disabled?(element = @element)      
      execute(element.operate { %|return element.disabled;| }, element)
    end

    def operate_by_locator(element)
      js.operate(%|var element = #{element.locator};
|, yield)
    end
  
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

    # Checkboxes/Radios have the same name, different values    
    def handle_form_element_name_match(element)
      element_capture = %|element = elements[i];break;|
      if element.respond_to?(:by_value) and element.by_value
%|if (elements[i].value == '#{element.by_value}') {
  #{element_capture}
}|        
      else
        element_capture
      end
    end
    private :handle_form_element_name_match

    def operate_by_title(element, &block)
      operate_by(element, 'title', &block)
    end

    def operate_by_action(element, &block)
      operate_by(element, 'action', &block)
    end

    def operate_by_text(element, &block)
      operate_by(element, 'innerText', &block)
    end

    def operate_by(element, attribute)
      js.operate(%|var elements = document.getElementsByTagName('#{element.tag}');
var element = undefined;
for (var i = 0; i < elements.length; i++) {
  if (elements[i].#{handle_match(element, attribute)}) {
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

    def click_alert
      execute_system_events(%|
tell window 1
	if button named "OK" exists then
		click button named "OK"
	end if
end tell|)
    end 
    
    def click_security_warning(label)
      execute_system_events(%|
tell window 1
	tell sheet 1
		tell group 2
			if button named "#{label}" exists then
				click button named "#{label}"
				return "#{EXTRA_ACTION_SUCCESS}"
			end if
		end tell
	end tell
end tell|, true)
    end

    def for_table(element)
      AppleScripter.new(TableJavaScripter.new(element))
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

    def exists?
      @document.exists
    end
    def execute_script(script)
      @document.do_JavaScript(script)
    end

    private

    def tag_names(element = @element)
      t_names = element.tag.kind_of?(Array) ? element.tag : [element.tag]
      "[" + (t_names.map { |t_name| "\"#{t_name.downcase}\"" }.join(", ")) + "]"
    end

    def execute(script, element = nil)
      response = eval_js(script)
      case response
        when NO_RESPONSE
          nil
        when ELEMENT_NOT_FOUND
          raise element_not_found_exception(element)
        when TABLE_CELL_NOT_FOUND
          raise UnknownCellException, "Unable to locate a table cell with #{element.how} of #{element.what}"
        when FRAME_NOT_FOUND
          raise UnknownFrameException, "Unable to locate a frame with name #{element.element_name}"
        else
          response
      end
    end

    def element_not_found_exception(element)
      if element.is_frame?
        return UnknownFrameException.new("Unable to locate a frame, using :#{element.how} and \"#{element.what}\"")
      end
      UnknownObjectException.new("Unable to locate #{element.element_name}, using :#{element.how} and \"#{element.what}\"")
    end
    
    def execute_and_ignore(script)
      eval_js(script)
      nil
    end

    # Must have "Enable access for assistive devices" checked in System Preferences > Universal Access
    def execute_system_events(script, capture_result = false)
result = `osascript <<SCRIPT
tell application "System Events" to tell process "Safari"  
	#{script}
end tell
SCRIPT`
      
      if capture_result && result
        return result.chomp 
      end
    end
    
    def page_load(extra_action = nil)      
      yield
      sleep 1
      
      tries = 0
      TIMEOUT.times do |tries|        
        if "complete" == eval_js("return DOCUMENT.readyState") && !@document.URL.get.blank?
          sleep 0.4          
          handle_client_redirect
          break
        elsif extra_action
          result = extra_action.call
          break if result == EXTRA_ACTION_SUCCESS
        else
          sleep 1
        end
      end
      raise "Unable to load page within #{TIMEOUT} seconds" if tries == TIMEOUT-1
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
