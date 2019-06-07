Rails.application.routes.draw do
  # For details on the DSL available within this file, see http://guides.rubyonrails.org/routing.html
  get '/lists', to: 'lists#index'
  get '/lists/:id', to: 'lists#show'
  post '/lists', to: 'lists#create'
  delete '/lists/:id', to: 'lists#delete'
  put '/lists/:id', to: 'lists#update'

end
