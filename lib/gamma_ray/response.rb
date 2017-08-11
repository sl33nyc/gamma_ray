module GammaRay
  class Response
    attr_reader :status, :error

    def initialize(status = 200, error = nil)
      @status = status
      @error  = error
    end
  end
end
