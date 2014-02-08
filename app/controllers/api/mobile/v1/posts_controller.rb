class Api::Mobile::V1::PostsController < ApiController

  def index
    category = Category.find params[:category_id]
    render nothing: true, status: 404 and return if category.nil?
    page = params[:page] || 1
    per_page = 15
    search = search_by_category(category.name, page, per_page)
    articles = search.results[:articles].to_a
    events = search.results[:events].to_a
    r = articles.concat(events).sort{|a, b| a.publish_at <=> b.publish_at }.collect{|post|
      image = post.image.as_json[:image]
      if post.is_a? Article
        post.as_json(only: [:id, :title, :subtitle, :body, :tags, :publish_at], include: [:categories, users: { only: [:id, :first_name, :last_name, :about, :image] }])
            .merge(type: 'article', image: image, uid: 'ar%s' % post.id)
      elsif post.is_a? Event
        post.as_json(only: [:id, :title, :subtitle, :body, :tags, :starts_at, :ends_at, :location, :map], include: [:categories, users: { only: [:id, :first_name, :last_name, :about, :image] }])
            .merge(type: 'event', image: image, uid: 'ev%s' % post.id )
      end
    }
    render json: r
  end

  def show
    m = params[:id].match(/([a-z]{2})(\d+)/)
    render nothing: true and return if m.nil?
    id = m[2]
    @model = case m[1]
              when 'ar' then Article.find(id)
              when 'ev' then Event.find(id)
            end
    view = 'api/mobile/v1/%s/show' % @model.class.name.downcase.pluralize
    render view
  end

  private

  def search_by_category(category, page, per_page)
    now = Time.now
    Tire.multi_search(page: page, per_page: per_page) do |ms|

      ms.search :articles, load:true, index: Article.index_name do |s|
        s.query do
          boolean do
            must { range :publish_at, { lte: now } }
            must { range :status, { gt: Status::Pending } }
            must { string 'categories:%s' % category }
          end
        end
        s.sort { by :publish_at, :desc }
      end

      ms.search :events, load:true, index: Event.index_name do |s|
        s.query do
          boolean do
            must { range :starts_at, { lte: now } }
            must { range :ends_at, { gte: now } }
            must { range :status, { gt: Status::Pending } }
            must { string 'categories:%s' % category }
          end
        end
        s.sort { by :starts_at, :asc }
      end

    end
  end

end
