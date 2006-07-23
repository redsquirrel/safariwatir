require 'watir/exceptions'
require 'safariwatir/scripter'
require 'safariwatir/core_ext'

module Watir
  include Watir::Exception

  module Clickable
    def click
      @scripter.highlight(self) do
        click_element
      end
    end    
  end

  module Elements
    class AlertWindow
      def initialize(scripter)
        @scripter = scripter
      end
      
      def click
        @scripter.click_alert_ok
      end
    end

    class HtmlElement
      def_init :scripter, :how, :what
      attr_reader :how, :what

      # Hooks for subclasses
      def tag; end
      def speak; end

      def name
        self.class.name.split("::").last
      end

      def operate(&block)
        send("operate_by_" + how.to_s, &block)
      end

      protected
      
      def operate_by_id(&block)
        @scripter.operate_by_id(self, &block)        
      end
      def operate_by_index(&block)
        @scripter.operate_by_index(self, &block)        
      end
      def operate_by_name(&block)
        @scripter.operate_by_name(self, &block)        
      end
      def operate_by_text(&block)
        @scripter.operate_on_link(self, &block)        
      end
      def operate_by_url(&block)
        @scripter.operate_on_link(self, &block)        
      end
      def operate_by_value(&block)
        @scripter.operate_by_input_value(self, &block)
      end
    end

    class Form < HtmlElement
      def_init :scripter, :how, :what

      def submit
        @scripter.submit_form(self)
      end
      
      def tag; "FORM"; end
    end
    
    class InputElement < HtmlElement
      include Clickable
      
      def speak
        @scripter.speak_value_of(self)
      end

      # Hooks for subclasses
      def by_value; end
    end
    
    class ContentElement < HtmlElement
      include Clickable

      def text
        @scripter.get_text_for(self)
      end

      def speak
        @scripter.speak_text_of(self)
      end      
    end
    
    class Button < InputElement
    end
    
    class Checkbox < InputElement
      def_init :scripter, :how, :what, :value
      def by_value
        @value
      end
      alias :set :click
    end

    class Div < ContentElement
    end

    class Label < ContentElement
      protected
      
      def operate_by_text(&block)
        @scripter.operate_on_label(self, &block)
      end
    end

    class Link < InputElement
      def click
        @scripter.highlight(self) do
          click_link
        end
      end
    end

    class Radio < Checkbox
    end

    class SelectList < InputElement
      def select(label)
        @scripter.highlight(self) do
          select_option(:text, label)
        end
      end

      def select_value(value)
        @scripter.highlight(self) do
          select_option(:value, value)
        end
      end
      
      def speak
        @scripter.speak_options_for(self)
      end
    end

    class Span < ContentElement
    end

    class TextField < InputElement
      def set(value)
        @scripter.highlight(self) do
          clear_text_input
          value.length.times do |i|
            append_text_input(value[i, 1])
          end
        end
      end
      
      def getContents
        @scripter.get_value_for(self)
      end
      
      def verify_contains(expected)
        actual = getContents
        expected == actual
      end
    end

    class Password < TextField
    end
  end
  
  class Safari
    include Elements

    attr_reader :scripter

    def self.start(url = nil)
      safari = new
      safari.goto(url) if url
      safari
    end
    
    def initialize
      @scripter = AppleScripter.new
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
    
    def goto(url)
      scripter.navigate_to(url)
    end

    def button(how, what)
      Button.new(scripter, how, what)
    end

    def checkbox(how, what, value = nil)
      Checkbox.new(scripter, how, what, value)
    end

    def div(how, what)
      Div.new(scripter, how, what)
    end

    def form(how, what)
      Form.new(scripter, how, what)
    end

    def image(how, what)
      Button.new(scripter, how, what)
    end

    def label(how, what)
      Label.new(scripter, how, what)
    end
    
    def link(how, what)
      Link.new(scripter, how, what)
    end

    def password(how, what)
      Password.new(scripter, how, what)
    end

    def radio(how, what, value = nil)
      Radio.new(scripter, how, what, value)
    end

    def select_list(how, what)
      SelectList.new(scripter, how, what)
    end
    
    def span(how, what)
      Span.new(scripter, how, what)
    end
    
    def text_field(how, what)
      TextField.new(scripter, how, what)
    end
    
    def contains_text(what)
      text = scripter.document_text
      case what
        when Regexp:
          text =~ what
        when String:
          text.index(what)
        else
          raise MissingWayOfFindingObjectException
        end
    end
  end # class Safari
end
