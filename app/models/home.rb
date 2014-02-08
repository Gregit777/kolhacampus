class Home

  class << self

    DEFAULT_SIZE = 10 # default search result size

    @@status_query = lambda do |boolean|
      boolean.must { string 'status:[%s TO %s]' % [Status::Confirmed, Status::Reconfirm] }
    end

    def load_items(home_data, components_data)
      config = Hash[home_data.collect{|section, items|
        [section, items.collect{|item|
          model, id = item['id'].split(Configuration::DELIMITER)
          {
            id: id.to_i,
            model: model
          }
        }]
      }]
      models = {}
      config.values.each do |items|
        items.each do |item|
          models[item[:model]] ||= []
          models[item[:model]] << item[:id]
        end
      end

      search = Tire.multi_search do |ms|
        models.each do |model, ids|
          plural_model = model.pluralize
          m = ('search_%s' % plural_model).to_sym
          self.send m, ms, ids
        end
      end

      process_results(search, config, components_data)
    end

    def search_events(ms, ids)
      from = Time.now
      to = from + 1.week
      ms.search :events, index: Event.index_name, load: true do |s|
        s.query do
          boolean &@@status_query
        end
        s.filter :or, {:terms => {:id => ids} },
                 {:range => {:begins_at => { :gte => from, :lt => to } }}

        s.sort { by :begins_at, :asc }
        page = 1
        search_size = DEFAULT_SIZE
        s.from (page - 1) * search_size
        s.size search_size
      end
    end

    def search_articles(ms, ids)
      ms.search :articles, index: Article.index_name, load: true do |s|
        s.query do
          boolean &@@status_query
        end
        s.filter :terms, :id => ids
        s.sort { by :publish_at, :asc }
        page = 1
        search_size = DEFAULT_SIZE
        s.from (page - 1) * search_size
        s.size search_size
      end
    end

    def search_albums(ms, ids)
      ms.search :albums, index: Album.index_name, load: true do |s|
        s.query do
          boolean &@@status_query
        end
        s.filter :terms, :id => ids
        s.sort { by :publish_at, :asc }
        page = 1
        search_size = DEFAULT_SIZE
        s.from (page - 1) * search_size
        s.size search_size
      end
    end

    def search_updates(ms, ids)
      ms.search :updates, index: Update.index_name, load: true do |s|
        s.query do
          boolean &@@status_query
        end
        s.filter :terms, :id => ids
        s.sort { by :publish_at, :asc }
        page = 1
        search_size = DEFAULT_SIZE
        s.from (page - 1) * search_size
        s.size search_size
      end
    end

    def search_tracklists(ms, ids)
      to = Time.now
      from = to - 1.week
      ms.search :tracklists, index: Tracklist.index_name, load: true do |s|
        s.query do
          boolean &@@status_query
        end
        s.filter :or, {:terms => {:id => ids} },
                      {:range => {:publish_at => { :gte => from, :lt => to } }}

        s.sort { by :publish_at, :asc }
        page = 1
        search_size = DEFAULT_SIZE
        s.from (page - 1) * search_size
        s.size search_size
      end
    end

    def process_results(search, config, components_data)
      search_results = search.results
      results = {}
      config.each do |section, items|
        results[section] = []
        section_ids = []
        items.each do |item|
          section_ids << item[:id]
          model = item[:model].pluralize.to_sym
          documents = search_results[model]
          results[section].concat documents.select{|doc| doc.id == item[:id] }
        end
        next if section == 'headlines'
        model = section == 'today' ? 'events' : section
        max = components_data[section]
        backfill = max - items.size
        documents = search_results[model]
        if backfill > 0 && !documents.nil?
          results[section].concat documents.select{|doc| !section_ids.include?(doc.id) }[0..backfill]
        end
      end
      Hash[results.collect{|section, items|
        [section, items.collect{|item|
          model_name = item.class.name.downcase
          fields = case model_name
                     when 'event' then [:id, :title, :begins_at, :ends_at, :image]
                     when 'tracklist' then [:id, :publish_at]
                     else [:id, :title, :publish_at, :image]
                   end
          if model_name == 'tracklist'
            item.as_json(only: fields, methods: :title).merge({model: model_name, image: item.display_image})
          else
            item.as_json(only: fields).merge({model: model_name})
          end
        }]
      }]
    end

  end

end