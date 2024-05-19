require 'faraday'

module HttpClient
  class Shelly1
    attr_reader :conn
    def initialize(ip_address)
      @ip_address = ip_address
      @conn = Faraday.new(url: "http://#{ip_address}")
    end

    def update_relay_state(value)
      @conn.get("relay/0?turn=#{value}")
    end
  end
end
