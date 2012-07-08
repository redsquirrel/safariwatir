require 'watir/exceptions'
require 'safariwatir/scripter'
require 'safariwatir/core_ext'
require 'safariwatir/element_attributes'
require 'safariwatir/locators'
require 'forwardable'

module Watir
  include Watir::Exception

  class ElementCollection < Array

    def [](idx)
      super(idx - 1)
    end

  end

  module PageContainer
    def html
      @scripter.document_html
    end
    
    def text
      @scripter.document_text(self)
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

      def is_frame?; false; end

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

      def flash
        10.times {@scripter.highlight(self) {sleep 0.05} }
      end

    end

    
    class FrameElement < HtmlElement
      def is_frame?; true; end
      def tag; ["frame", "iframe"]; end
    end

    class Frame
      include Container
      include PageContainer
      include Locators
      extend Forwardable

      def initialize(parent_tag, scripter_obj, find_how, find_what)
        @parent = parent_tag
        @scripter = scripter_obj
        @how = find_how
        @what = find_what
        @frame_element = FrameElement.new(parent_tag, scripter_obj, find_how, find_what)
      end

      def tag; ["frame", "iframe"]; end

      def document_locator; locator; end

      def locator
        self.send("locator_by_#{how}".to_sym).to_s + ".contentDocument"
      end
  
      attr_reader :parent, :how, :what, :scripter, :frame_element

      def_delegators :frame_element, :class_name, :id, :name, :title, :src, :alt, :exist?, :exists?
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

    class Dd < ContentElement
      def tag; "DD"; end
    end

    class Dl < ContentElement
      def tag; "DL"; end
    end

    class Dt < ContentElement
      def tag; "DT"; end
    end
    
    class Em < ContentElement
      def tag; "EM"; end
    end

    class Image < HtmlElement
      include Clickable
      
      def tag; "IMG"; end
    end
    
    class Button < InputElement
      def tag; ["INPUT", "BUTTON"]; end
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
      def tag; "PRE"; end
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

      def iotuibd
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

      alias :selected_options :selected_values

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
      def parent; @select_list; end

      def selected?
        selected_value = html_method(:selected) ? html_method(:selected) : ""
        selected_value != ""
      end

      def select
        @scripter.highlight(self) do
          select_option
        end
      end
      
      def text
        @scripter.get_text_for(self)
      end

      def tag; "OPTION"; end
    end

    class Span < ContentElement
      def tag; "SPAN"; end
    end

    class Strong < ContentElement
      def tag; "STRONG"; end
    end

    class Map < InputElement
      def tag; "MAP"; end
    end

    class Table < ContentElement
      def_init :parent, :scripter, :how, :what
      attr_reader :parent, :how, :what
      
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
    
    class TableRow < ContentElement
      def initialize(scripter, how, what, table = nil)
        @scripter = scripter
        @how = how
        @what = what
        @table = table
      end

      attr_reader :table, :how, :what

      alias :parent :table
            
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

    class TextArea2 < InputElement
      def tag; ["textarea"]; end

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

    class FileField < TextField
      def input_type; "file"; end

      def set(value)
        @scripter.set_file_field(self, value.to_s)
      end
    end

    class Password < TextField
      def input_type; "password"; end
    end

    class Ol < ContentElement
      def tag; "OL"; end
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
    
    def areas
      child_tag_list do |idx|
        Area.new(self, scripter, :index, idx)
      end
    end

    def button(how, what)
      Button.new(self, scripter, how, what)
    end

    def buttons
      child_tag_list do |idx|
        Button.new(self, scripter, :index, idx)
      end
    end

    def cell(how, what)
      TableCell.new(self, scripter, how, what)
    end

    def checkbox(how, what, value = nil)
      Checkbox.new(self, scripter, how, what, value)
    end

    def checkboxes
      child_tag_list do |idx|
        Checkbox.new(self, scripter, :index, idx, nil)
      end
    end

    def dd(how, what)
      Dd.new(self, scripter, how, what)
    end

    def dds
      child_tag_list do |idx|
        Dd.new(self, scripter, :index, idx)
      end
    end

    def div(how, what)
      Div.new(self, scripter, how, what)
    end
    
    def divs
      child_tag_list do |idx|
        Div.new(self, scripter, :index, idx)
      end
    end

    def dl(how, what)
      Dl.new(self, scripter, how, what)
    end

    def dls
      child_tag_list do |idx|
        Dl.new(self, scripter, :index, idx)
      end
    end

    def dt(how, what)
      Dt.new(self, scripter, how, what)
    end

    def dts
      child_tag_list do |idx|
        Dt.new(self, scripter, :index, idx)
      end
    end

    def em(how, what)
      Em.new(self, scripter, how, what)
    end

    def ems
      child_tag_list do |idx|
        Em.new(self, scripter, :index, idx)
      end
    end

    def p(how, what)
      P.new(self, scripter, how, what)
    end

    def ps
      child_tag_list do |idx|
        P.new(self, scripter, :index, idx)
      end
    end

    def pre(how, what)
      Pre.new(self, scripter, how, what)
    end

    def pres
      child_tag_list do |idx|
        Pre.new(self, scripter, :index, idx)
      end
    end

    def form(how, what)
      Form.new(self, scripter, how, what)
    end

    def forms
      child_tag_list do |idx|
        Form.new(self, scripter, :index, idx)
      end
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

    def images
      child_tag_list do |idx|
        Image.new(self, scripter, :index, idx)
      end
    end

    def label(how, what)
      Label.new(self, scripter, how, what)
    end

    def labels
      child_tag_list do |idx|
        Label.new(self, scripter, :index, idx)
      end
    end

    def li(how, what)
      Li.new(self, scripter, how, what)
    end
    
    def lis
      child_tag_list do |idx|
        Li.new(self, scripter, :index, idx)
      end
    end

    def link(how, what)
      Link.new(self, scripter, how, what)
    end

    def links
      child_tag_list do |idx|
        Link.new(self, scripter, :index, idx)
      end
    end

    def map(how, what)
      Map.new(self, scripter, how, what)
    end

    def maps
      child_tag_list do |idx|
        Map.new(self, scripter, :index, idx)
      end
    end

    def password(how, what)
      Password.new(self, scripter, how, what)
    end

    def passwords
      child_tag_list do |idx|
        Password.new(self, scripter, :index, idx)
      end
    end

    def radio(how, what, value = nil)
      Radio.new(self, scripter, how, what, value)
    end

    def row(how, what)
      TableRow.new(self, scripter, how, what)
    end

    def rows
      child_tag_list do |idx|
        TableRow.new(self, scripter, :index, idx)
      end
    end

    def select_list(how, what)
      SelectList.new(self, scripter, how, what)
    end

    def select_lists
      child_tag_list do |idx|
        SelectList.new(self, scripter, :index, idx)
      end
    end
    
    def span(how, what)
      Span.new(self, scripter, how, what)
    end

    def spans
      child_tag_list do |idx|
        Span.new(self, scripter, :index, idx)
      end
    end

    def strong(how, what)
      Strong.new(self, scripter, how, what)
    end

    def strongs
      child_tag_list do |idx|
        Strong.new(self, scripter, :index, idx)
      end
    end

    def table(how, what)
      Table.new(self, scripter, how, what)
    end
    
    def tables
      child_tag_list do |idx|
        Table.new(self, scripter, :index, idx)
      end
    end

    def text_field(how, what)
      TextField.new(self, scripter, how, what)
    end
    
    def text_fields
      child_tag_list do |idx|
        TextField.new(self, scripter, :index, idx)
      end
    end

    def text_area(how, what)
      TextArea.new(self, scripter, how, what)
    end

    def text_area2(how, what)
      TextArea.new(self, scripter, how, what)
    end

    def file_field(how, what)
      FileField.new(self, scripter, how, what)
    end

    def file_fields
      child_tag_list do |idx|
        FileField.new(self, scripter, :index, idx)
      end
    end

    def ol(how, what)
      Ol.new(self, scripter, how, what)
    end

    def ols
      child_tag_list do |idx|
        Ol.new(self, scripter, :index, idx)
      end
    end

    def ul(how, what)
      Ul.new(self, scripter, how, what)
    end

    def uls
      child_tag_list do |idx|
        Ul.new(self, scripter, :index, idx)
      end
    end

    def child_tag_list(&child_tag_blk)
        values = ElementCollection.new
        index = 1
        loop do
          child_tag = child_tag_blk.call(index)
          break unless child_tag.exists?
          values << child_tag
          index += 1
        end
        values
    end
    
    def contains_text(what)
      case what
      when Regexp
        text =~ what
      when String
        text.index(what)
      else
        raise TypeError
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
      if url.match(/:\/\//)
        url_with_scheme = url
      else
        url_with_scheme = "http://#{url}"
      end
      scripter.navigate_to(url_with_scheme)
    end
    
    # Reloads the page
    def reload
      scripter.reload
    end
    alias :refresh :reload
    
    def exists?
      @scripter.exists?
    end
    def execute_script(script)
      @scripter.execute_script(script)
    end
    def status
      execute_script("window.status")
    end
    def back
      execute_script("window.history.go(-1)")
      sleep 0.01 # Browser#"goes to the previous page" spec fails without this line
    end
    def forward
      execute_script("window.history.go(1)")
      sleep 0.01 # Browser#"goes to the next page" spec fails without this line
    end
  end # class Safari

  
  class WebKit < Safari
    def initialize
      @scripter = AppleScripter.new(JavaScripter.new, :appname => "WebKit")
      @scripter.ensure_window_ready
      set_slow_speed
    end
  end # class WebKit
    
end
