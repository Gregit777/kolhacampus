require 'base64'
require Rails.root.join('lib/mini_magick')

ActiveAdmin.register Feed do

  menu parent: 'Tracklists & Feeds'

  actions :edit, :update, :index

  index do
    column :program
    column :publish_at
    default_actions
  end

  form :partial => 'form'

  controller do

    def update
      feed = Tracklist.find(params[:id])
      item_feed = []
      unless params[:feed].nil?
        params[:feed].each do |id, f|
          next if id.to_s == 'new_feed_image'
          orig_feed = feed.feed.select{|i| i['id'] == id }.first
          if f.key?('feed')
            orig_feed['feed'] = f['feed'].map{|item| JSON.parse(item)}
          else
            orig_feed['feed'] = []
          end
          if f.key?('image')
            h = get_image_item(f['image'])
            orig_feed['feed'] << h
          end
          item_feed << orig_feed
        end

        if params[:feed].key?(:new_feed_image)
          h = get_image_item(params[:feed][:new_feed_image])
          feed_item = Tracklist.get_item_feed_object(nil, Time.now)
          feed_item['feed'] << h
          item_feed << feed_item
        end
      end

      feed.update_attribute :feed, item_feed
      redirect_to edit_admin_feed_url(feed)
    end

    private

    def get_image_item(obj)
      src = MiniMagick::Image.read(obj)
      mime_type = obj.content_type
      image = Kolhacampus::MiniMagick.resize_to_fill src, 92, 92
      data_uri = ['data:',mime_type,';base64,',Base64.encode64(image.to_blob)].join('')
      h = {
          type: 'image',
          image: data_uri
      }
    end

  end
end
