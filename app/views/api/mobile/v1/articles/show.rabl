object @model
attributes :id, :title, :subtitle, :body, :publish_at, :tags
node do |article|
  {
    uid: 'ar%s' % article.id,
    type: 'article',
    categories: article.categories.as_json
  }
end
node do |article|
  article.image.as_json
end
child :users, :object_root => false do
  extends 'api/mobile/v1/users/show'
end