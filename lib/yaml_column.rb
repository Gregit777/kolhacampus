class YAMLColumn < ActiveRecord::Coders::YAMLColumn
  def load(yaml)
    return object_class.new if object_class != Object && yaml.nil?
    return yaml unless yaml.is_a?(String) && yaml =~ /^---/
    begin
      # if yaml sting contains old Syck-style encoded UTF-8 characters
      # then replace them with corresponding UTF-8 characters
      # FIXME: is there better alternative to eval?
      if yaml =~ /\\x[0-9A-F]{2}/
        #yaml = yaml.gsub(/(\\x[0-9A-F]{2})+/){|m| eval "\"#{m}\""}.force_encoding("UTF-8")
        yaml = yaml.gsub(/\\x([0-9A-F]{2})/){[$1].pack("H2")}.force_encoding("UTF-8")
      end
      obj = YAML.load(yaml)

      unless obj.is_a?(object_class) || obj.nil?
        raise SerializationTypeMismatch,
              "Attribute was supposed to be a #{object_class}, but was a #{obj.class}"
      end
      obj ||= object_class.new if object_class != Object

      obj
    rescue
      yaml
    end
  end
end