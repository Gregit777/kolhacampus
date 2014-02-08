object @tracklist
attributes :id, :ondemand_url, :program_id
node :publish_at do |tracklist|
  tracklist.publish_at.utc
end
node :start_time do |tracklist|
  tracklist.start_time
end

node :description do |tracklist|
  tracklist.description_i18n
end

child :program, :object_root => false do
  extends 'api/mobile/v1/programs/show'
end
node :feed_items do |tracklist|
  tracklist.feed_items
end