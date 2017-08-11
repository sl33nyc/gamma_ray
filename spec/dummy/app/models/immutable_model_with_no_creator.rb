class ImmutableModelWithNoCreator < ApplicationRecord
  include GammaRay::ActiveRecord::Model

  has_autolog
end
