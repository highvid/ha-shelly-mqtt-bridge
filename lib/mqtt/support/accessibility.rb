module Mqtt
  module Support
    module Accessibility
      def relay_mqtt
        Config.singleton.relay_mqtt
      end

      def home_assistant_mqtt
        Config.singleton.home_assistant_mqtt
      end

      def aggregated_command_topics
        Config.singleton.aggregated_command_topics
      end

      def aggregated_topics
        Config.singleton.aggregated_topics
      end
    end
  end
end
