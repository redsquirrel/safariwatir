$LOAD_PATH.unshift(File.dirname(__FILE__) + '/../lib/')
require "safariwatir"

Browser = Watir::Safari
include Watir::Exception