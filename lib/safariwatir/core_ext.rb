# Why shouldn't this be in core Ruby?
class Class
  def def_init(*attrs)
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

class String
  def quote_safe
    gsub(/"/, '\"')
  end
end

class Object
  def blank?
    if respond_to?(:strip)
      strip.empty?
    elsif respond_to?(:empty?)
      empty?
    else
      !self
    end
  end
end
