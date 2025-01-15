module Mqtt
  module Support
    module Publishable
      UPDATE_COMMANDS = %w[announce status_update].freeze
      UPDATE_DELAY = 600
      UPDATE_TOPIC = 'shellies/command'.freeze

      def threads
        super + [thread_for_status_updates]
      end

      def thread_for_status_updates
        @thread_for_status_updates ||= Thread.new do
          loop do
            UPDATE_COMMANDS.each do |update_command|
              AppLogger.debug("Retrying command #{update_command}")
              Config.singleton.relay_mqtt.publish(UPDATE_TOPIC, update_command)
            end
            sleep UPDATE_DELAY
          end
        end
      end
    end
  end
end
