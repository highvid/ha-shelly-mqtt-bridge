require 'faraday'

module HttpClient
  class ShellyPlus2Pm
    attr_reader :conn
    def initialize(ip_address)
      @ip_address = ip_address
      @conn = Faraday.new(url: "http://#{ip_address}")
    end

    def update_output_state(output, value)
      @conn.get("rpc/Switch.Set?id=#{output}&on=#{value == 'on'}")
    end
  end
end
