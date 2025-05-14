module Mqtt
  module Clients
    class ShellyDimmer < ShellyDimmer2
      # This class is a placeholder for the Gen3 Shelly Dimmer.
      def update_light_state(turn, brightness)
        mqtt_client.publish("#{base_topic}/command/light:0", "set,#{turn == 'on'},#{brightness}")
      end
    end
  end
end
