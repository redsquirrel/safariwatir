require 'watir/exceptions'
require 'safariwatir/scripter'
require 'safariwatir/core_ext'
require 'safariwatir/element_attributes'
require 'safariwatir/locators'

module Watir
  include Watir::Exception

  module PageContainer
    def html
      @scripter.document_html
    end
    
    def text
      @scripter.document_text
    end

    def title
      @scripter.document_title
    end
  end

  module Container
    attr_reader :scripter
    private :scripter

    DEFAULT_TYPING_LAG = 0.08

    def set_fast_speed
      @scripter.typing_lag = 0
    end
    
    def set_slow_speed
      @scripter.typing_lag = DEFAULT_TYPING_LAG
    end
    
    def speed=(how_fast)
      case how_fast
      when :fast then set_fast_speed
      when :slow then set_slow_speed
      else
        raise ArgumentError, "Invalid speed: #{how_fast}"
      end
    end

    module Clickable
      def click
        @scripter.highlight(self) do
          click_element
        end
      end    
    end

    class AlertWindow
      def_init :scripter
      
      def click
        @scripter.click_alert
      end
    end

    class SecurityWarningWindow
      def initialize(scripter, url)
        @scripter = scripter
        @url = url
      end
      
      def continue
        handle_click("Continue")
      end
      
      def cancel
        handle_click("Cancel")
      end
      
    private
      def handle_click(button)
        if @url
          @scripter.navigate_to(@url) do
            @scripter.click_security_warning(button)
          end
        else
          @scripter.click_security_warning(button)
        end
      end
    end

    class HtmlElement
      def_init :parent, :scripter, :how, :what
      attr_reader :how, :what, :parent

      include Locators

      # required by watir specs
      extend ElementAttributes
      html_attr_reader :class_name, "class"
      html_attr_reader :id
      html_attr_reader :name
      html_attr_reader :title
      html_attr_reader :src
      html_attr_reader :alt
      html_method_reader :value

      def type; nil; end

      # overridden in derivitives
      def tag
        raise RuntimeError, "tag not provided for #{element_name}"
      end

      # overridden in derivitives
      def speak
        @scripter.speak("#{element_name}'s don't know how to speak.")
      end

      def exists?
        unless [Fixnum, String, Regexp].any? { |allowed_class| what.kind_of?(allowed_class) }
          raise TypeError.new("May not search using a 'what' value of class #{what.class.name}")
        end
        @scripter.element_exists?(self)
      end
      alias :exist? :exists?
      
      def element_name
        self.class.name.split("::").last
      end

      def html_method name
        @scripter.get_method_value(name, self)
      end

      def attr name
        @scripter.get_attribute(name, self)
      end

      def operate(&block)
        @scripter.operate_by_locator(self, &block)
      end

      OPERATIONS = {
        :id => "by_id",
        :alt => "by_alt",
        :action => "by_action",
        :index => "by_index",
        :class => "by_class",
        :name => "by_name",
        :text => { "Link" => "on_link",
                   "Label" => "by_text",
                   "Span"  => "by_text" },
        :url => "on_link",
        :value => "by_input_value",
        :caption => "by_input_value",
        :src => "by_src",
        :title => "by_title",
        :xpath => "by_xpath",
      }

    end

    class Frame
      include Container
      include PageContainer
      include Locators

      def tag; ["frame", "iframe"]; end

      def document_locator; locator; end

      def locator
        self.send("locator_by_#{how}".to_sym).to_s + ".contentDocument"
      end
  
      attr_reader :parent, :how, :what, :scripter

      def_init :parent, :scripter, :how, :what
    end

    class Form < HtmlElement
      def_init :parent, :scripter, :how, :what

      def submit
        @scripter.submit_form(self)
      end
      
      def tag; "FORM"; end
    end
    
    class InputElement < HtmlElement
      include Clickable
      
      html_attr_reader :type

      def speak
        @scripter.speak_value_of(self)
      end
      
      def enabled?
        !@scripter.element_disabled?(self)
      end
      
      def disabled?
        @scripter.element_disabled?(self)
      end

      def tag; "INPUT"; end

      # Hook for derivitives
      def by_value; end
    end
    
    class ContentElement < HtmlElement
      include Clickable
      include Container

      def html
        @scripter.get_html_for(self)
      end

      def text
        @scripter.get_text_for(self)
      end

      def speak
        @scripter.speak_text_of(self)
      end      
    end
    
    class Image < HtmlElement
      include Clickable
      
      def tag; "IMG"; end
    end
    
    class Button < InputElement
      include ButtonLocators
    end
        
    class Checkbox < InputElement
      def_init :parent, :scripter, :how, :what, :value
      
      include InputLocators

      def input_type; "checkbox"; end

      def by_value
        @value
      end

      # Contributed by Kyle Campos
      def checked?
        @scripter.checkbox_is_checked?(self)
      end
      
      def set(check_it = true)
        return if check_it && checked?
        return if !check_it && !checked?
        click
      end
    end

    class Header < ContentElement
      
      def initialize(parent, scripter, how, what, h_size = 1)
        super(parent, scripter, how, what)
        @size = 1
      end
      
      def tag; "H#{@size}"; end
    end

    class Div < ContentElement
      def tag; "DIV"; end
    end
    
    class P < ContentElement
      def tag; "P"; end
    end

    class Pre < ContentElement
      def tag; "Pre"; end
    end

    class Label < ContentElement

      html_attr_reader :for
      def tag; "LABEL"; end
    end

    class Link < ContentElement
      def click
        @scripter.highlight(self) do
          click_link
        end
      end

      def click_jquery
        @scripter.highlight(self) do
          click_link_jquery
        end
      end

      def href
        attr('href') || ''
      end
      alias :url :href

      def id
        attr('id') || ''
      end

      def title
        attr('title') || ''
      end

      def class_name
        attr('class') || ''
      end

      def style
        attr('style') || ''
      end

      def name
        attr('name') || ''
      end

      def tag; "A"; end
    end

    class Radio < Checkbox
      def input_type; "radio"; end
    end

    class SelectList < InputElement
      def select(label)
        option(:text, label).select
      end
      
      def select_value(value)
        option(:value, value).select
      end
      
      def option(how, what)
        Option.new(@scripter, self, how, what)
      end
      
      def selected_values
        values = []
        index = 1
        loop do
          option = option(:index, index)
          break unless option.exists?
          values << option if option.selected?
          index += 1
        end
        values.map {|o| o.text } #TODO?
      end

      def selected_value
        selected_values.first
      end
      
      def speak
        @scripter.speak_options_for(self)
      end
      
      def tag; "SELECT"; end
    end

    class Option < InputElement
      def_init :scripter, :select_list, :how, :what
      
      def select
        @scripter.highlight(self) do
          select_option
        end
      end
      
      def operate(&block)
        @select_list.operate(&block)
      end

      def exists?
        @scripter.option_exists?(self)
      end
      alias :exist? :exists?
      
      def selected?
        @scripter.option_selected?(self)
      end
      
      def text
        @scripter.get_text_for(self)
      end

      def tag; "OPTION"; end
    end

    class Span < ContentElement
      def tag; "SPAN"; end
    end

    class Map < InputElement
      def tag; "MAP"; end
    end

    class Table
      def_init :parent, :scripter, :how, :what
      attr_reader :how, :what
      
      def each
        # TODO
      end
      
      def [](index)
        TableRow.new(@scripter, :index, index, self)
      end
      
      def row_count
        # TODO
      end
      
      def column_count
        # TODO
      end

      def tag; "TABLE"; end
    end
    
    class TableRow
      def initialize(scripter, how, what, table = nil)
        @scripter = scripter
        @how = how
        @what = what
        @table = table
      end

      attr_reader :table, :how, :what
            
      def each
        # TODO
      end
      
      def [](index)
        TableCell.new(@scripter, :index, index, self)
      end

      def column_count
        # TODO
      end

      def tag; "TR"; end
    end
    
    class TableCell < ContentElement
      def initialize(scripter, how, what, row = nil)
        @scripter = scripter.for_table(self)
        set_slow_speed # TODO: Need to inherit this somehow

        @how = how
        @what = what
        @row = row
      end
      
      attr_reader :how, :what, :row

      def operate(&block)
        @scripter.operate_by_table_cell(self, &block)
      end

      def tag; "TD"; end
    end

    class TextField < InputElement
      include InputLocators
      def input_type; "text"; end

      def set(value)
        value = value.to_s
        @scripter.focus(self)
        @scripter.highlight(self) do
          clear_text_input
          value.length.times do |i|
            append_text_input(value[i, 1])
          end
        end
        @scripter.blur(self)
      end
      
      def getContents
        @scripter.get_value_for(self)
      end

      alias :value :getContents
      
      def verify_contains(expected)
        actual = getContents
        case expected
        when Regexp
          actual.match(expected) != nil
        else
          expected == actual
        end
      end
    end
    
    class TextArea < TextField
      def tag; ["input", "textarea"]; end
    end

    class FileField < TextField
      def input_type; "file"; end

      def set(value)
        @scripter.set_file_field(self, value.to_s)
      end
    end

    class Password < TextField
    end

    class Ul < ContentElement
      def tag; "UL"; end
    end
    
    class Li < ContentElement
      def tag; "LI"; end
    end

    class Area < InputElement
      def tag; "AREA"; end
    end

    # Elements

    def area(how, what)
      Area.new(self, scripter, how, what)
    end
    
    def button(how, what)
      Button.new(self, scripter, how, what)
    end

    def cell(how, what)
      TableCell.new(self, scripter, how, what)
    end

    def checkbox(how, what, value = nil)
      Checkbox.new(self, scripter, how, what, value)
    end

    def div(how, what)
      Div.new(self, scripter, how, what)
    end
    
    def p(how, what)
      P.new(self, scripter, how, what)
    end

    def pre(how, what)
      Pre.new(self, scripter, how, what)
    end

    def form(how, what)
      Form.new(self, scripter, how, what)
    end

    def frame(how, what)
      Frame.new(self, scripter, how, what)
    end
    
    def h1(how, what)
      Header.new(self, scripter, how, what, 1)
    end

    def h2(how, what)
      Header.new(self, scripter, how, what, 2)
    end

    def h3(how, what)
      Header.new(self, scripter, how, what, 3)
    end

    def h4(how, what)
      Header.new(self, scripter, how, what, 4)
    end

    def h5(how, what)
      Header.new(self, scripter, how, what, 5)
    end

    def h6(how, what)
      Header.new(self, scripter, how, what, 6)
    end

    def image(how, what)
      Image.new(self, scripter, how, what)
    end

    def label(how, what)
      Label.new(self, scripter, how, what)
    end

    def li(how, what)
      Li.new(self, scripter, how, what)
    end
    
    def link(how, what)
      Link.new(self, scripter, how, what)
    end

    def map(how, what)
      Map.new(self, scripter, how, what)
    end

    def password(how, what)
      Password.new(self, scripter, how, what)
    end

    def radio(how, what, value = nil)
      Radio.new(self, scripter, how, what, value)
    end

    def row(how, what)
      TableRow.new(self, scripter, how, what)
    end

    def select_list(how, what)
      SelectList.new(self, scripter, how, what)
    end
    
    def span(how, what)
      Span.new(self, scripter, how, what)
    end

    def table(how, what)
      Table.new(self, scripter, how, what)
    end
    
    def text_field(how, what)
      TextField.new(self, scripter, how, what)
    end
    
    def text_area(how, what)
      TextArea.new(self, scripter, how, what)
    end

    def file_field(how, what)
      FileField.new(self, scripter, how, what)
    end

    def ul(how, what)
      Ul.new(self, scripter, how, what)
    end
    
    def contains_text(what)
      case what
      when Regexp
        text =~ what
      when String
        text.index(what)
      else
        raise MissingWayOfFindingObjectException
      end
    end
  end

  class Safari
    include Container
    include PageContainer

    def self.start(url = nil)
      safari = new
      safari.goto(url) if url
      safari
    end
    
    def initialize
      @scripter = AppleScripter.new(JavaScripter.new)
      @scripter.ensure_window_ready
      set_slow_speed
    end
    
    # URL of page
    def url
      scripter.url
    end

    def locator; "document"; end
    def document_locator; "document"; end
    
    # Hide's Safari
    def hide
      scripter.hide
    end
    
    def close
      scripter.close
    end
    
    def quit
      scripter.quit
    end
    
    def alert
      AlertWindow.new(scripter)
    end

    def security_warning
      SecurityWarningWindow.new(scripter)
    end

    def security_warning_at(url)
      SecurityWarningWindow.new(scripter, url)
    end
    
    def goto(url)
      scripter.navigate_to(url)
    end
    
    # Reloads the page
    def reload
      scripter.reload
    end
    alias :refresh :reload
  end # class Safari

  
  class WebKit < Safari
    def initialize
      @scripter = AppleScripter.new(JavaScripter.new, :appname => "WebKit")
      @scripter.ensure_window_ready
      set_slow_speed
    end
  end # class WebKit
    
end
