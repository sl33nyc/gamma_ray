class ImmutableModelWithCreator < ApplicationRecord
  include GammaRay::ActiveRecord::Model
  belongs_to :created_by, class_name: 'User'

  has_autolog
end