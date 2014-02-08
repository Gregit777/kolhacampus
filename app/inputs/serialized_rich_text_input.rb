class SerializedRichTextInput < Formtastic::Inputs::TextInput

  def attr_key
    options[:attr][:key]
  end

  def input_html_options
    super.merge({
      :name => "#{object_name}[#{association_primary_key || method}][#{attr_key}]",
      :value => value,
      :buttons => ['bold', 'italic', '|', 'unorderedlist', 'orderedlist', 'link'],
      :minHeight => 150,
      :id => "#{object_name}_#{association_primary_key || method}_#{attr_key}"
    })
  end

  def to_html
    input_wrapping do
      label_html <<
          builder.text_area(method, input_html_options) <<
          %{
          <script type="text/javascript">
            $(document).ready(function(){
              $('##{input_html_options[:id]}').redactor({
                buttons: [#{input_html_options[:buttons].map{|b| "'#{b}'" }.join(',')}],
                minHeight: #{input_html_options[:minHeight]}
              });
            });
          </script>
        }.html_safe
    end
  end

  def value
    attr_hash = object.respond_to?(method) ? object.send(method) : { attr_key => {} }
    if attr_hash[attr_key].nil?
      ''
    else
      attr_hash[attr_key]
    end
  end
end