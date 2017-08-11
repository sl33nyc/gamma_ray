require 'gamma_ray/request'

module GammaRay
  class Client
    def initialize(attrs = {})
      @options = attrs
      @stream_name = attrs[:stream_name]
    end

    def track(event, properties={})
      fail ArgumentError, 'Must supply and event name as a non-empty string' if event.empty?
      fail ArgumentError, 'Properties must be a Hash'                        unless properties.is_a? Hash

      serialized = {}
      properties.each { |k, v| serialized[k] = serialize_value(v) }

      #put the event onto the kinesis queue
      GammaRay::Request.new.post(@stream_name, serialized)
    end

    private

    def serialize_value(value)
      value = value.utc        if value.respond_to?(:utc)
      value = value.iso8601(6) if value.respond_to?(:iso8601)
      return value
    end
  end
end
 