module Mqtt
  module Clients
    class ShellyPlus1Pm < Shelly1
      def update_relay_state(value, relay = 0)
        mqtt_client.publish(base_topic + "/command/switch:#{relay}", value)
      end
    end
  end
end
