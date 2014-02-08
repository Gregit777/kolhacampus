class KolHacampus.PostsController extends KolHacampus.ApplicationController
  routingKey: 'posts'

  @beforeAction only: "index", (params) ->
    id = parseInt(params.categoryId, 10)
    @set 'category', KolHacampus.Category.get('loaded.indexedByUnique.id').get(id)

  index: (params) ->
    category = @get('category')
    KolHacampus.Post.load({page: 1, category_id: category.get('id')}, (err, results) =>
      throw err if err
      @set 'posts', results
      @render()
    )
    @render(false)

  show: (params) ->
    KolHacampus.Post.find(params.id, (err, post) =>
      throw err if err
      @set 'post', post
      @render(source: 'posts/' + post.get('type'))
    )
    @render(false)