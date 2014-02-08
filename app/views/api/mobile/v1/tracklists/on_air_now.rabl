object @tracklist
attributes :id, :description, :publish_at, :ondemand_url, :program_id, :updated_at
node :tracks do |tracklist|
  @tracks
end
node :feed do |tracklist|
  tracklist.feed
end