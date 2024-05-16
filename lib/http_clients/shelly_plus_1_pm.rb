require 'faraday'

module HttpClient
  class ShellyPlus1PM
    attr_reader :conn
    def initialize(ip_address)
      @ip_address = ip_address
      @conn = Faraday.new(url: "http://#{ip_address}")
    end

    def update_output_state(value)
      @conn.get("rpc/Switch.Set?id=0&on=#{value == 'on'}")
    end
  end
end
