ActiveAdmin.register Article do

  menu parent: 'Posts'

  filter :title
  filter :categories

  form do |f|
    f.inputs do
      f.input :title
      f.input :subtitle, :input_html => { :rows => 5 }
      f.input :categories, as: :select2_multi, collection: Category.all.collect{|cat| [cat.name, cat.id]}
      f.input :tags, as: :select2_tags
      f.input :body, :as => :rich_text
      f.input :image, :hint => (f.template.image_tag(f.object.image.url) unless f.object.image.url.nil?)
      f.input :image_cache, :as => :hidden, :value => f.object.image.url
      f.input :status, :as => :select, :collection => Status.values
      f.input :publish_at, :as => :datetime_picker
    end
    f.buttons
  end

  index do
    column :title
    column :publish_at
    default_actions
  end

  controller do

    def permitted_params
      params.fetch(:article, {}).tap do |_params|
        _params[:tags] = _params[:tags].split(',')
        _params[:category_ids] = _params[:category_ids].select{|item| !item.blank? }
      end

      params.permit(article: [:title, :subtitle, :body, :image, :image_cache, :status, :publish_at, tags: [], category_ids: []])
    end

  end

end