class Major < ApplicationRecord
  belongs_to :department
  has_many :students
  extend ActiveModel::Callbacks
  define_model_callbacks :create, :update, :destroy, :commit, :rollback
  include GammaRay::ActiveRecord::Model
  has_autolog
end
