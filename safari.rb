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
    
    class Element
      init :scripter, :how, :what
    end
    
    class Button < Element
      def click
        @scripter.highlight(@how, @what) do |scripter|
          scripter.click_element
        end
      end
    end
    
    class Checkbox < Element
      def set
        @scripter.highlight(@how, @what) do |scripter|
          scripter.click_element
        end
      end
    end

    class Link < Element
      def click
        @scripter.highlight(@how, @what) do |scripter|
          scripter.click_link
        end
      end
    end
    
    class TextField < Element
      def set(value)
        @scripter.highlight(@how, @what) do |scripter|
          scripter.clear_text_input
          value.length.times do |i|
            scripter.append_text_input(value[i, 1])
          end
        end
      end
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
    
    def goto(url)
      scripter.navigate_to(url)
    end

    def text_field(how, what)
      TextField.new(scripter, how, what)
    end

    def checkbox(how, what)
      Checkbox.new(scripter, how, what)
    end
    
    def button(how, what)
      Button.new(scripter, how, what)
    end

    def link(how, what)
      Link.new(scripter, how, what)
    end
    
    def alert
      AlertWindow.new(scripter)
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