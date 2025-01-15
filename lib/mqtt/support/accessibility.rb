module Mqtt
  module Support
    module Accessibility
      def relay_mqtt
        Config.singleton.relay_mqtt
      end

      def home_assistant_mqtt
        Config.singleton.home_assistant_mqtt
      end

      def discovery?(topic)
        !!(topic =~ %r{shellies/[^ ]+/announce})
      end

      def online_message?(message)
        message == 'online'
      end

      def offline_message?(message)
        !online_message?(message)
      end

      def aggregated_topics = Config.singleton.aggregated_topics

      def aggregated_command_topics = Config.singleton.aggregated_command_topics

      def unhandled_command_topic(topic)
        AppLogger.warn "Unknown command handler for #{topic}"
      end

      def unhandled_topic(topic)
        AppLogger.warn "Unknown handler for #{topic}"
      end
    end
  end
end
