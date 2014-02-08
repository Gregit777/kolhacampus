object @model
attributes :id, :title, :subtitle, :body, :starts_at, :ends_at, :tags, :location, :map
node do |event|
  {
    uid: 'ev%s' % event.id,
    type: 'event',
    categories: event.categories.as_json
  }
end
node do |event|
  event.image.as_json
end
child :users, :object_root => false do
  extends 'api/mobile/v1/users/show'
end