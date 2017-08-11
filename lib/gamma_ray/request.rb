require 'gamma_ray/response'
require 'json'

module GammaRay
  class Request
    def initialize(options = {})
      @kinesis = Aws::Kinesis::Client.new(region: 'us-east-1')
    end

    def post(stream_name, batch)
      status, error = nil, nil

      begin
        @kinesis.put_record({
          stream_name: stream_name,
          data: batch.to_json,
          partition_key: Random.rand(10000).to_s
        })
        status = 200
        error = nil
      rescue Exception => e
        puts "-- EXCEPTION #{e} --"
        status = -1
        error = "Connection error: #{e}"
      end

      Response.new status, error
    end
  end
end
