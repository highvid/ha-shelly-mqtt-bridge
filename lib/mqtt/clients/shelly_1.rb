module Mqtt
  module Clients
    class Shelly1
      attr_reader :mqtt_client, :base_topic

      def initialize(mqtt_client, base_topic)
        @mqtt_client = mqtt_client
        @base_topic = base_topic
      end

      def update_relay_state(value, relay = 0)
        mqtt_client.publish(base_topic + "/relay/#{relay}/command", value)
      end
    end
  end
end
