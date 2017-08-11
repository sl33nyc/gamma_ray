module GammaRay
  module ActiveRecord
    class << self
      attr_writer :author
    end

    def self.author
      @author ||= {}
    end

    def self.reset_author
      @author = {}
    end
  end
end
