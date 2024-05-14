require 'faraday'

module HttpClient
  class ShellyDimmer2
    attr_reader :conn
    def initialize(ip_address)
      @ip_address = ip_address
      @conn = Faraday.new(url: "http://#{ip_address}")
    end

    def update_brightness(value)
      @conn.get("light/0?brightness=#{value}")
    end

    def update_light_state(value)
      @conn.get("light/0?turn=#{value}")
    end
  end
end
