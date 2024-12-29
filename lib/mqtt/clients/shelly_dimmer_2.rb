module Mqtt
  module Clients
    class ShellyDimmer2
      attr_reader :mqtt_client, :base_topic
      def initialize(mqtt_client, base_topic)
        @mqtt_client = mqtt_client
        @base_topic = base_topic
      end

      def update_light_state(turn, brightness)
        mqtt_client.publish(base_topic + "/light/0/set", {brightness:, turn:}.to_json)
      end
    end
  end
end
