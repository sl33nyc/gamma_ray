module GammaRay
  module ActiveRecord
    # Extensions to rails controllers. Provides convenient ways to pass certain
    # information to the model layer, with `controller_info` and `author`.
    # Also includes a convenient on/off switch, `enabled_for_controller`.
    module Controller
      def self.included(base)
        base.send :extend, ClassMethods
      end
      module ClassMethods

        def has_autolog(opts={})
          # Lazily include the instance methods so we don't clutter up
          # any more ActiveRecord models than we have to.
          send :include, InstanceMethods

          before_filter :set_gamma_ray_author
          after_filter :reset_gamma_ray_author
        end

      end

      module InstanceMethods
        protected

        # Returns the user who is responsible for any changes that occur.
        # By default this calls `current_user` and returns the result.
        def user_for_gamma_ray
          return unless defined?(current_user)
          return current_user
        end

        def get_user_hash(opts={})
          return {} unless user_for_gamma_ray

          attributes = ::GammaRay::ActiveRecord.configuration.author_attributes || {}

          if attributes.size > 0
            author_hash = {}
            attributes.each do |attr|
              author_hash[attr.to_sym] = user_for_gamma_ray.send(attr)
            end
            return author_hash
          end

          return user_for_gamma_ray.attributes
        end

        private

        def set_gamma_ray_author
          ::GammaRay::ActiveRecord.author = { author: get_user_hash }
        end

        def reset_gamma_ray_author
          ::GammaRay::ActiveRecord.reset_author
        end
      end
    end
  end
end
