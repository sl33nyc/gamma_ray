class Student < ApplicationRecord
  belongs_to :major
  extend ActiveModel::Callbacks
  define_model_callbacks :create, :update, :destroy, :commit, :rollback
  include GammaRay::ActiveRecord::Model
  has_autolog(:related_objects => ["major"])
end
