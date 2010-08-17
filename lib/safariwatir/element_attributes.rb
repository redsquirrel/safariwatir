module ElementAttributes
  def html_attr_reader(m_name, html_attribute = nil)
    attr_to_reference = (html_attribute ? html_attribute : m_name.to_s)
    define_method(m_name) do
      attr(attr_to_reference) ? attr(attr_to_reference) : ""
    end
  end
end
