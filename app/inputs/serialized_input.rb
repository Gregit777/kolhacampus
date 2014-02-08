class SerializedInput < Formtastic::Inputs::NumberInput

  def attr_key
    options[:attr] || 'other'
  end

  def input_html_options
    {
      :name => "#{object_name}[#{association_primary_key || method}][#{attr_key}]",
      :value => value
    }.merge(super)
  end

  def value
    if object.respond_to?(method)
      attr_hash = object.send(method) || { attr_key => '' }
      val = attr_hash[attr_key]
    else
      ''
    end
  end

end