require 'safari/scripter'
require 'safari/core_ext'
require 'watir/exceptions'

module Watir
  include Watir::Exception

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
        @scripter.operate_on_form_element(self, &block)        
      end
      def operate_by_text(&block)
        @scripter.operate_on_link(self, &block)        
      end
      def operate_by_url(&block)
        @scripter.operate_on_link(self, &block)        
      end
    end

    class Form < HtmlElement
      def_init :scripter, :how, :what

      def submit
        @scripter.submit_form(self)
      end
      
      def tag; "FORM"; end
    end
    
    class ClickableElement < HtmlElement      
      def click
        @scripter.highlight(self) do
          click_element
        end
      end

      # Hooks for subclasses
      def by_value; end
    end
    
    class Button < ClickableElement
    end
    
    class Checkbox < ClickableElement
      alias :set :click
    end

    class Label < ClickableElement
      protected
      
      def operate_by_text(&block)
        @scripter.operate_on_label(self, &block)
      end
    end

    class Link < ClickableElement
      def click
        @scripter.highlight(self) do
          click_link
        end
      end
    end

    class Radio < ClickableElement
      def_init :scripter, :how, :what, :value
      def by_value
        @value
      end
      alias :set :click
    end

    class SelectList < ClickableElement
      def select(label)
        @scripter.highlight(self) do
          select_option("text", label)
        end
      end

      def select_value(value)
        @scripter.highlight(self) do
          select_option("value", value)
        end
      end
    end

    class TextField < ClickableElement
      def set(value)
        @scripter.highlight(self) do
          clear_text_input
          value.length.times do |i|
            append_text_input(value[i, 1])
          end
        end
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

    def checkbox(how, what)
      Checkbox.new(scripter, how, what)
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