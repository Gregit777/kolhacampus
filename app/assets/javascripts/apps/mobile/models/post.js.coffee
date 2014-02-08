class KolHacampus.Post extends KolHacampus.BaseModel
  @resourceName: 'posts'
  @storageKey: 'api/mobile/v1/posts'
  @primaryKey: 'uid'

  @persist Batman.RailsStorage

  @hasMany 'categories',
    autoload: false
    saveInline: false
    inverseOf: 'post'

  @hasMany 'users',
    autoload: false
    saveInline: false
    inverseOf: 'post'

  # Use @encode to tell batman.js which properties Rails will send back with its JSON.
  @encode 'uid', 'title', 'subtitle', 'image', 'tags', 'publish_at', 'starts_at', 'ends_at', 'location', 'map', 'type'
  @encode 'body',
    decode: (value) ->
      value.replace(/<iframe([^>]+)width=\"(\d)+\"/g,"<iframe$1width=\"100%\"")
           .replace(/<iframe([^>]+)height=\"(480)\"/g,"<iframe$1height=\"240\"")
           .replace(/<embed[^>]+><\/embed>/g,'')
           .replace(/<object[^>]+>.+<\/object>/g,'')
           .replace(/\/third_party\//g, 'http://www.106fm.co.il/third_party/')

  @encode 'categories',
    decode: (categories, key, incomingJSON, outgoingObject, record) ->
      categories.forEach (json) ->
        KolHacampus.Category.find json.id, (err, category) ->
          if err
            category = new KolHacampus.Category json
          category.get('posts').add record
          category.save()

  @accessor 'like_url', ->
    "//www.facebook.com/plugins/like.php?href=http://www.106fm.co.il/posts/#{@get('uid')}&amp;width=150&amp;layout=button_count&amp;action=like&amp;show_faces=false&amp;share=false&amp;height=21&amp;appId=157859684256501"

  @encodeTimestamps()
