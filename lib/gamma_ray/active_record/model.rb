module GammaRay
  module ActiveRecord
    module Model
      def self.included(base)
        base.send :extend, ClassMethods
      end
      module ClassMethods
        def has_autolog(opts={})
          # Lazily include the instance methods so we don't clutter up
          # any more ActiveRecord models than we have to.
          send :include, InstanceMethods

          after_create   :record_create_gamma_ray
          after_update   :record_update_gamma_ray
          after_destroy  :record_destroy_gamma_ray
          after_commit   :record_commit_gamma_ray
          after_rollback :record_rollback_gamma_ray

          class_attribute :gamma_ray_options
          self.gamma_ray_options = (GammaRay::ActiveRecord.configuration.defaults || {}).merge(opts)

          class_attribute :gamma_ray_event
          self.gamma_ray_event = nil

          [:ignore, :only].each do |k|
            gamma_ray_options[k] = [gamma_ray_options[k]].flatten.compact.map { |attr| attr.is_a?(Hash) ? attr.stringify_keys : attr.to_s }
          end
        end

      end

      # Wrap the following methods in a module so we can include them only in the
      # ActiveRecord models that declare `has_autolog`.
      module InstanceMethods
        def gamma_ray_versions
          all_versions = [related_versions]

          # include local versions for immutable resources
          # Since each time we update an immutable object, a new entry is created.
          # we will have to get this history into versions
          if defined?(ImmutableHelper) and self.is_a?(ImmutableHelper)
            all_versions << local_mutated_versions
          else
            all_versions << main_versions
          end

          all_versions.flatten.sort { |a,b| Time.parse(b['occurred_at']) <=> Time.parse(a['occurred_at']) }
        end

        protected

        def prefix
          [self.class.table_name, self.id.to_s.rjust(9, "0").scan(/.{1,3}/)].flatten.join('/')
        end

        def related_versions
          related_versions = []

          return related_versions if self.gamma_ray_options[:related_objects].blank?

          self.gamma_ray_options[:related_objects].each do |related_obj|
            [self.send(related_obj)].flatten.each do |obj|
              related_versions << obj.main_versions
            end
          end
          return related_versions
        end

        def main_versions
          client = Aws::S3::Client.new(region: 'us-east-1')
          resource = Aws::S3::Resource.new(client: client)
          obj_versions = []
          begin
            bucket = resource.bucket(GammaRay::ActiveRecord.configuration.bucket_name)
            bucket.objects(prefix: prefix).each do |obj_summary|
              obj_versions << JSON.parse(obj_summary.get.body.read)
            end
          rescue Aws::S3::Errors::NoSuchBucket
            puts "#{GammaRay::ActiveRecord.configuration.bucket_name} does not exists"
          end
          return obj_versions
        end

        def local_mutated_versions
          immutable_object_histories = self.class.unscoped.where(uuid: self.uuid).order('created_at asc')
          immutable_object_histories.map.with_index do |ioh, i|
            # first object here is the very first(initial) version...
            # so no changes made, and the event was 'creation'
            if i > 0
              changes = get_changes(immutable_object_histories[i-1], ioh)
              event = 'updated'
            else
              changes = {}
              event = 'created'
            end

            performed_by = ioh.try(:created_by)

            {
              'uuid' => ioh.uuid,
              'class_name' => ioh.class.to_s,
              'table_name' => ioh.class.table_name,
              'id' => ioh.id,
              'changes' => changes,
              'object' => ioh.attributes,
              'occurred_at' => ioh.created_at.to_s,
              'env' => GammaRay::ActiveRecord.configuration.env,
              'event' => event,
              'updated_by_id' => performed_by.try(:id),
              'updated_by_full_name' => "#{performed_by.try(:first_name)} #{performed_by.try(:last_name)}",
              'updated_by_role' => performed_by.try(:role),
              'updated_by_user_type' => performed_by.try(:user_type),
              'bucket_name' => GammaRay::ActiveRecord.configuration.bucket_name
            }
          end
        end

        private

        def get_changes(prev_version, current_version)
          prev_version = prev_version.attributes.except('id', 'created_at', 'deprecated_at')
          current_version = current_version.attributes.except('id', 'created_at', 'deprecated_at')

          changed = prev_version.to_a - current_version.to_a

          changed.reduce({}) do |collection, keyVal|
            collection.merge(keyVal[0] => [keyVal[1], current_version[keyVal[0]]])
          end
        end

        def record_create_gamma_ray
          set_or_update_gamma_ray_event!('created')
        end

        def record_update_gamma_ray
          set_or_update_gamma_ray_event!('updated')
        end

        def record_destroy_gamma_ray
          set_or_update_gamma_ray_event!('destroyed')
        end

        def should_send_gamma_ray
          return false unless GammaRay::ActiveRecord.configuration.turn_on

          !filter_gamma_ray_properties(self.changes, gamma_ray_options).empty?
        end

        def record_commit_gamma_ray
          flush_gamma_ray_event
        end

        def record_rollback_gamma_ray
          self.gamma_ray_event = nil
        end

        def flush_gamma_ray_event
          return true if self.gamma_ray_event.blank?

          GammaRay::ActiveRecord.track(self.gamma_ray_event[:event], self.gamma_ray_event)
          self.gamma_ray_event = nil

          return true
        end

        def set_or_update_gamma_ray_event!(event_type)
          return true unless should_send_gamma_ray
          if self.gamma_ray_event.blank?
            self.gamma_ray_event = attributes_to_gamma_ray_properties.merge(event: event_type)
          else
            self.gamma_ray_event[:changes].merge!(filter_gamma_ray_properties((self.changes || {}).dup, gamma_ray_options))
          end
          return true
        end

        def attributes_to_gamma_ray_properties()
          properties_changes = filter_gamma_ray_properties((self.changes || {}).dup, gamma_ray_options)
          new_obj_attributes = filter_gamma_ray_properties(self.attributes.dup, gamma_ray_options)
          result = {
            uuid: SecureRandom.uuid,
            class_name: self.class.to_s,
            table_name: self.class.table_name,
            id: self.id,
            changes: properties_changes,
            object: new_obj_attributes,
            occurred_at: Time.now.to_s,
            env: GammaRay::ActiveRecord.configuration.env,
            bucket_name: GammaRay::ActiveRecord.configuration.bucket_name
          }

          result.merge!(::GammaRay::ActiveRecord.author)

          return result
        end

        def filter_gamma_ray_properties(props={}, opts={})
          props.delete_if { |key| opts[:ignore].include? key } if (opts[:ignore] || []).size > 0
          props.keep_if   { |key| opts[:only].include? key } if (opts[:only] || []).size > 0
          return props
        end
      end
    end
  end
end
