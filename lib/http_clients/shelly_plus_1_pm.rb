require 'faraday'

module HttpClient
  class ShellyPlus1Pm < Shelly1Pm
    def update_output_state(value)
      @conn.get("rpc/Switch.Set?id=0&on=#{value == 'on'}")
    end
  end
end
