ActiveAdmin.register Tracklist do

  menu parent: 'Tracklists & Feeds'

  filter :program
  filter :publish_at

  index do
    column :program
    column :publish_at
    default_actions
  end

  form :partial => 'form'

  controller do

    def create
      data = params[:tracklist][:tracks]
      params[:tracklist][:tracks] = Hash[*data.each_with_index.map{|a, i| [i, a]}.flatten]
      super
    end

    def update
      data = params[:tracklist][:tracks]
      params[:tracklist][:tracks] = Hash[*data.each_with_index.map{|a, i| [i, a]}.flatten] if params[:tracklist].key?(:tracks)
      super
    end

    def permitted_params
      params.permit(tracklist: [:program_id, :description, :publish_at, :status]).tap do |whitelisted|
        whitelisted[:tracklist][:tracks] = params[:tracklist][:tracks]
      end
    end

  end
end
