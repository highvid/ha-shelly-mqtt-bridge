require 'faraday'

module HttpClient
  class Shelly25
    attr_reader :conn
    def initialize(ip_address)
      @ip_address = ip_address
      @conn = Faraday.new(url: "http://#{ip_address}")
    end

    def update_relay_state(relay, value)
      @conn.get("relay/#{relay}?turn=#{value}")
    end
  end
end
