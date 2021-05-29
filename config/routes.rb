Rails.application.routes.draw do
  root 'static_pages#top'
  get '/signup', to: 'users#new'
  # get '/csv', to: 'users#csv_user_attendance'
  post '/csv' , to: 'users#csv_user_attendance'
  # ログイン機能
  get    '/login', to: 'sessions#new'
  post   '/login', to: 'sessions#create'
  delete '/logout', to: 'sessions#destroy'

  resources :users do
    # get "csv_user_attendance", on: :member
    member do
      get 'edit_basic_info'
      patch 'update_basic_info'
      get 'attendances/edit_one_month'
      patch 'attendances/update_one_month'
    end
    resources :attendances, only: :update
  end
end