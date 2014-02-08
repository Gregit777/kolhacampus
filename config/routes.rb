require Rails.root.join('lib/useragent_constraint')

Kolhacampus::Application.routes.draw do

  namespace 'api' do
    namespace 'mobile' do
      namespace 'v1' do

        resources :programs, only: [:index, :show] do
          resources :feeds, controller: 'tracklists', only: [:index, :show] do
            get 'at/:datetime', to: 'tracklists#by_datetime', on: :collection, as: 'by_datetime'
          end
        end

        resources :feeds, only: [:index, :show, :update], controller: 'tracklists' do
          post on: :member, as: 'update', action: 'add_comment'
        end

        resources :posts, :users, only: [:index, :show]

        resources :events, :articles, only: [:show]

        resources :home, :about, only: [:index]

      end
    end

    namespace 'shared' do
      namespace 'v1' do

        resource :autocomplete, :controller => 'autocomplete', :only => [] do
          get :title, :defaults => { :format => 'json' }
        end

      end
    end
  end

  match '/', to: 'mobile_home#index', constraints: MobileUseragentConstraint.new , via: 'get', as: 'mobile_root'
  # Match all requests made from mobile and route to mobile_home controller
  match '*path', to: 'mobile_home#index', constraints: MobileUseragentConstraint.new , via: 'get'
  root 'home#index'

  devise_for :users, ActiveAdmin::Devise.config
  ActiveAdmin.routes(self)

  match '*not_found', to: 'errors#error_404', via: 'get'
end
