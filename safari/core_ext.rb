# Why shouldn't this be in core Ruby?
class Module
  def init(*attrs)
    constructor = %|def initialize(|
    constructor << attrs.map{|a| a.to_s }.join(",")
    constructor << ")\n"
    attrs.each do |attribute|
      constructor << "@#{attribute} = #{attribute}\n"
    end
    constructor << "end"
    class_eval(constructor)
  end
end