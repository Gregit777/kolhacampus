class Select2AutocompleteInput < Formtastic::Inputs::HiddenInput

  def attr_key
    options[:attr][:key]
  end

  def attr_field
    options[:attr][:field]
  end

  def attr_index
    options[:attr][:index]
  end

  def dom_id
    "#{object_name}_#{association_primary_key || method}_#{attr_index}_#{attr_key}"
  end

  def search_index
    options[:attr][:search_index]
  end

  def input_html_options
    {
      :name => "#{object_name}[#{association_primary_key || method}][#{attr_key}][][#{attr_field}]",
      :value => value,
      :style => 'width:50%',
      'data-search' => search_index
    }.merge(super)
  end

  def value
    attr_hash = object.respond_to?(method) ? object.send(method) : { attr_key => [] }
    if attr_hash[attr_key][attr_index].nil?
      ''
    else
      attr_hash[attr_key][attr_index][attr_field]
    end
  end

  def to_html
    input_wrapping do
      label_html <<
      builder.hidden_field(method, input_html_options) <<
      %{
        <script type="text/javascript">
          window.select2_fields = window.select2_fields || [];
          window.select2_fields.push("#{dom_id}");
        </script>
      }.html_safe
    end
  end

end