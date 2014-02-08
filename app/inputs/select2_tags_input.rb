class Select2TagsInput < Formtastic::Inputs::HiddenInput

  def dom_id
    "#{object_name}_#{association_primary_key || method}"
  end

  def input_html_options
    {
      :value => value,
      :style => 'width:50%'
    }.merge(super)
  end

  def value
    val = object.respond_to?(method) ? object.send(method) : ''
    val.is_a?(Array) ? val.join(',') : val
  end

  def to_html
    input_wrapping do
      label_html <<
        builder.hidden_field(method, input_html_options) <<
        %{
        <script type="text/javascript">
          window.select2_tags_fields = window.select2_tags_fields || [];
          window.select2_tags_fields.push("#{dom_id}");
        </script>
      }.html_safe
    end
  end

end