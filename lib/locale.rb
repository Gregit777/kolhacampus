module I18n
  module Backend
    class Simple
      def translations_by_locales(*keys)
        send(:init_translations) unless initialized?
        h = {}
        keys.each do |locale|
          next unless translations.has_key?(locale)
          h[locale] = translations[locale]
        end
        h
      end
    end
  end

  module Model

    def method_missing(m, *args, &block)
      method = m.to_s
      if method =~ /_i18n/
        base_attr = method.gsub /_i18n/, ''
        suffix = I18n.locale == :en ? '_en' : ''
        attr = [base_attr, suffix].join('').to_sym
        if self.respond_to? attr
          self.send attr
        else
          super
        end
      else
        super
      end
    end

  end
end