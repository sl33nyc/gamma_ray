module GammaRay
  module ActiveRecord
    class Configuration
      attr_accessor :stream_name
      attr_accessor :bucket_name
      attr_accessor :env
      attr_accessor :turn_on
      attr_accessor :defaults
      attr_accessor :author_attributes
    end

    class << self
      attr_writer :configuration
    end

    def self.configuration
      @configuration ||= Configuration.new
    end

    def self.reset
      @configuration = Configuration.new
    end

    def self.configure
      yield(configuration)
    end
  end
end
