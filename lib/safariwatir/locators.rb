require File.dirname(__FILE__) + '/../watir/exceptions'

module Locators
  
  def document_locator
    parent.document_locator
  end

  def locator
    self.send("locator_by_#{how.to_s}".to_sym)
  end

  def locator_by_text
    locator_by_method("innerText")
  end

  def locator_by_value
    locator_by_method("value")
  end

  def locator_by_src
    locator_by_attribute("src")
  end

  def locator_by_alt
    locator_by_attribute("alt")
  end

  def locator_by_src
    locator_by_attribute("src")
  end

  def locator_by_method(m_name)
    "findByMethodValue(#{parent.locator}, #{tag_names}, \"#{m_name}\", \"#{what.to_s}\")[0]"
  end

  def locator_by_attribute(attribute_name)
    "findByAttributeValue(#{parent.locator}, #{tag_names}, \"#{attribute_name}\", \"#{what.to_s}\")[0]"
  end

  def locator_by_xpath
    xpath = what.gsub(/"/, "\'")
    "findByXPath(#{document_locator}, #{parent.locator}, \"#{xpath}\")"
  end

  def locator_by_name
    locator_by_attribute("name")
  end

  def locator_by_index
    "findByTagNames(#{parent.locator}, #{tag_names})[#{what.to_i - 1}]"
  end

  def locator_by_class
    locator_by_attribute("class")
  end

  def locator_by_id
    "#{document_locator}.getElementById(\"#{what.to_s}\")"
  end

  def tag_names
      t_names = tag.kind_of?(Array) ? tag : [tag]
      "[" + (t_names.map { |t_name| "\"#{t_name.downcase}\"" }.join(", ")) + "]"
  end

  def method_missing(*args)
    if args[0].to_s =~ /locator_by_/
      raise Watir::Exception::MissingWayOfFindingObjectException
    end
    super(*args)
  end

end
