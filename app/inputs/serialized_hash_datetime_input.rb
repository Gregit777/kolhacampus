class SerializedHashDatetimeInput < Formtastic::Inputs::DatetimePickerInput

  def attr_key
    options[:attr][:key]
  end

  def attr_field
    options[:attr][:field]
  end

  def attr_index
    options[:attr][:index]
  end

  def input_html_options
    {
      :name => "#{object_name}[#{association_primary_key || method}][#{attr_key}][][#{attr_field}]",
      :value => value,
      :step => 3600
    }.merge(super)
  end

  def value
    attr_hash = object.respond_to?(method) ? object.send(method) : { attr_key => [] }
    if attr_hash[attr_key][attr_index].nil? || attr_hash[attr_key][attr_index][attr_field].nil?
      (Time.now + 1.hour).strftime('%Y-%m-%dT%H:00:00')
    else
      attr_hash[attr_key][attr_index][attr_field]
    end
  end

end