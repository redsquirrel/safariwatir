module Locators

  def locator
    self.send("locator_by_#{how}".to_sym)
  end

  def locator_by_name
    "findByNameAttribute(#{parent.locator}, \"#{what.to_s}\", #{tag_names})"
  end

  def locator_by_index
    "findByTagNames(#{parent.locator}, #{tag_names})[#{what.to_i - 1}]"
  end

  def locator_by_id
    "#{parent.locator}.getElementById(\"#{what.to_s}\")"
  end

  def tag_names
      t_names = tag.kind_of?(Array) ? tag : [tag]
      "[" + (t_names.map { |t_name| "\"#{t_name.downcase}\"" }.join(", ")) + "]"
  end

end
