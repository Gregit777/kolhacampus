class Select2SerializedMultiInput < Formtastic::Inputs::SelectInput

  def dom_id
    "#{object_name}_#{association_primary_key || method}_#{attr_key}"
  end

  def attr_key
    options[:attr]
  end

  def input_html_options
    super.merge({
      :name => "#{object_name}[#{association_primary_key || method}][#{attr_key}][]",
      :multiple => true,
      :style => 'width:50%'
    })
  end

  def to_html
    input_wrapping do
      hidden_input <<
        label_html <<
        (options[:group_by] ? grouped_select_html : select_html) <<
        %{
        <script type="text/javascript">
          window.select2_multi_fields = window.select2_multi_fields || [];
          window.select2_multi_fields.push("#{dom_id}");
        </script>
      }.html_safe
    end
  end

end