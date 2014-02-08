class RichTextInput < Formtastic::Inputs::TextInput

  def input_html_options
    {
      :buttons => ['bold', 'italic', '|', 'unorderedlist', 'orderedlist', 'link'],
      :minHeight => 150
    }.merge(super)
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
end