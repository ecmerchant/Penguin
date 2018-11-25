require 'resque/server'

Rails.application.routes.draw do

  root to: 'products#show'

  get 'candidates/show'
  get 'candidates/show/:asin', to: 'candidates#show'

  get 'products/search'
  get 'products/show'
  post 'products/import'

  get 'accounts/setup'
  post 'accounts/setup'

  mount Resque::Server.new, at: "/resque"

  devise_scope :user do
    get '/users/sign_out' => 'devise/sessions#destroy'
    get '/sign_in' => 'devise/sessions#new'
  end
  mount RailsAdmin::Engine => '/admin', as: 'rails_admin'
  devise_for :users, :controllers => {
   :registrations => 'users/registrations'
  }
  # For details on the DSL available within this file, see http://guides.rubyonrails.org/routing.html
end
