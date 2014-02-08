ActiveAdmin.register Configuration do

  filter :name
  actions :index, :update
  config.batch_actions = false

  index do
    column :name
    actions defaults: true do |configuration|
      url = send 'modify_admin_configuration_url', configuration
      link_to "Edit", url
    end
  end

  member_action :modify, :method => :get do
    @configuration = Configuration.find params[:id]
    @page_title = 'Edit %s configuration' % @configuration.name.humanize
    cb = ('%s_config_items' % @configuration.name).to_sym
    @config_items, @meta_data = @configuration.send cb
    render 'admin/configurations/edit_%s' % @configuration.name
  end

  controller do

    def update
      params[:configuration][:data] = params[:configuration][:data].to_hash
      super
    end

    def permitted_params
      data = []
      params.require(:configuration).tap do |configuration|
        configuration[:data].each do |key, value|
          if value.is_a? Array
            h = {}
            if value.first.is_a? Hash
              h[key] = value.collect{|val| val.keys }.flatten.uniq

            else
              h[key] = []
              configuration[:data][key] = value.select{|v| !v.blank? }
            end
            data << h
          else
            data << key
          end
        end
      end
      params.permit(:configuration => [:data => data])
    end
  end

end