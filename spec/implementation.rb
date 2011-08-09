$LOAD_PATH.unshift("../lib")
require "safariwatir"

include Watir::Exception

WatirSpec.implementation do |imp|
  imp.name = :safariwatir
  imp.browser_class = Watir::Safari
end
