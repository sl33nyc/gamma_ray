Rails.application.routes.draw do
  resources :students, only: %i[create update destroy]
  resources :teachers, only: %i[create update destroy]
  resources :departments, only: %i[create update destroy]
  resources :majors, only: %i[create update destroy]
end
