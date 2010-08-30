$LOAD_PATH.unshift(File.dirname(__FILE__) + '/../lib/')
require "safariwatir"
require "sinatra/base"

Browser = Watir::Safari
include Watir::Exception

module WatirSpec

  class Server < Sinatra::Base
    def self.host
      "127.0.0.1"
    end
  end

end
