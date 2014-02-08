class Article < ActiveRecord::Base

  include Tire::Model::Search
  include Tire::Model::Callbacks

  settings :analysis => {
    :filter => {
      :title_ngram  => {
        "type"     => "edgeNGram",
        "max_gram" => 15,
        "min_gram" => 2
      }
    },
    :analyzer => {
      :index_ngram_analyzer => {
        "type" => "custom",
        "tokenizer" => "standard",
        "filter" => [ "standard", "lowercase", "title_ngram" ]
      },
      :search_ngram_analyzer => {
        "type" => "custom",
        "tokenizer" => "standard",
        "filter" => [ "standard", "lowercase"]
      },
    }
  }

  mapping do
    indexes :id,              index: :not_analyzed
    indexes :subtitle,        analyzer: 'snowball'
    indexes :publish_at,      type: 'date'
    indexes :categories,      type: 'string', analyzer: 'keyword', as: 'category_names'
    indexes :tags,            type: 'string', analyzer: 'keyword'
    indexes :status,          type: 'integer'
    indexes :title,           type: 'multi_field', fields: {
      title: { type: "string"},
      :"title.autocomplete" => { search_analyzer: "search_ngram_analyzer", index_analyzer: "index_ngram_analyzer", type: "string"}
    }
  end

  has_and_belongs_to_many :users
  has_and_belongs_to_many :categories

  serialize :tags, Array

  mount_uploader :image, DisplayPhotoUploader

  def to_indexed_json
    h = {
      id: id,
      title: title,
      subtitle: subtitle,
      publish_at: publish_at,
      status: status,
      tags: tags,
      categories: category_names
    }
    h.to_json
  end

  private

  def category_names
    self.categories.pluck :name
  end

end
