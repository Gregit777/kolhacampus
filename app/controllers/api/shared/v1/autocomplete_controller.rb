class Api::Shared::V1::AutocompleteController < ApplicationController
  respond_to :json

  def title
    q = params[:q]
    index = params[:index]
    if index.nil?
      @search = autocomplete_all(q, 'title.autocomplete', :title)
    else
      @search = autocomplete_by_index(q, index, 'title.autocomplete', :title)
    end
    r = @search.results.as_json.flatten.collect{|item| item.select{|k| k == 'id' || k == 'title' || k == '_type'}}
    render :json => r.to_json
  end

  private

  def autocomplete_all(q, field, sort)
    Tire.multi_search do |ms|

      ms.search :articles, index: Article.index_name do |s|
        s.query {string '%s:%s' % [field, q] }
        s.sort { by sort, :asc }
      end

      ms.search :events, index: Event.index_name do |s|
        s.query {string '%s:%s' % [field, q] }
        s.sort { by sort, :asc }
      end

      ms.search :tracklists, index: Tracklist.index_name do |s|
        s.query {string '%s:%s' % [field, q] }
        s.sort { by sort, :asc }
      end

    end
  end

  def autocomplete_by_index(q, index, field, sort)
    model = Kernel.const_get index.singularize.capitalize
    unless model.nil?
      Tire.search index, index: model.index_name do |s|
        s.query {string '%s:%s' % [field, q] }
        s.sort { by sort, :asc }
      end
    end
  end

end
