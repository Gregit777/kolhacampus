ActiveAdmin.register Program do

  menu parent: 'Programs & Schedules'

  index do
    column :name
    default_actions
  end

  filter :status

  form do |f|
    f.inputs do
      f.input :name
      f.input :name_en, :label => 'Name (English)'
      f.input :description, :input_html => { :rows => 5 }
      f.input :image, :hint => (f.template.image_tag(f.object.image.url) unless f.object.image.url.nil?)
      f.input :image_cache, :as => :hidden, :value => f.object.image.url
      f.input :active
      f.input :live
      f.input :is_set, :label => 'Set'
      f.input :status, :as => :select, :collection => Status.values, :include_blank => false
    end

    f.actions
  end

  controller do

    def permitted_params
      params.permit(program: [:name, :name_en, :description, :image, :active, :live, :is_set, :status])
    end

  end
end
