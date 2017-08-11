require "gamma_ray/active_record/author"
require "gamma_ray/active_record/configuration"
require "gamma_ray/active_record/model"
require "gamma_ray/active_record/controller"
require 'request_store'

module GammaRay
  module ActiveRecord
    def self.client
      unless (self.configuration.stream_name)
        warn "The GammaRay stream stream_name is undefined: Set GammaRay::ActiveRecord.configuration.stream_name"
        return
      end

      unless (self.configuration.bucket_name)
        warn "The GammaRay stream stream_name is undefined: Set GammaRay::ActiveRecord.configuration.bucket_name"
        return
      end

      @client ||= {}
      @client[self.configuration.stream_name] ||= GammaRay::Client.new(stream_name: self.configuration.stream_name)
    end

    def self.track(event_name, props={})
      return unless self.client
      self.client.track(event_name, props)
    end
  end
end

if defined?(::ActionController)
  ::ActiveSupport.on_load(:action_controller) do
    include GammaRay::ActiveRecord::Controller
  end
end

if defined?(::ActiveRecord)
  ::ActiveSupport.on_load(:active_record) do
    include GammaRay::ActiveRecord::Model
  end
end
