module Mqtt
  module Support
    module Listenable
      def threads
        super + [thread_for_state_listeners, thread_for_command_listeners]
      end

      def thread_for_state_listeners
        @thread_for_state_listeners ||= Thread.new do
          relay_mqtt.get do |topic, message|
            AppLogger.debug "Got message from topic #{topic} -> #{message}"
            if aggregated_topics[topic].present?
              handle(topic, aggregated_topics[topic], message)
            else
              AppLogger.warn "Unknown handler for #{topic}"
            end
          end
        rescue StandardError => e
          AppLogger.exception(e)
          exit(1)
        end
      end

      def thread_for_command_listeners
        @thread_for_command_listeners ||= Thread.new do
          home_assistant_mqtt.get do |topic, message|
            if aggregated_command_topics[topic].present?
              handle(topic, aggregated_command_topics[topic] || [], message, with_update: true)
            elsif topic == HOME_ASSISTANT_UPDATES_TOPIC
              check_and_publish_availability(message)
            else
              unhandled_topic(topic)
            end
          end
        rescue StandardError => e
          AppLogger.exception(e, context: 'Exception in relay listener')
          exit(1)
        end
      end

      def force_publish_online!
        AppLogger.debug 'Force updating all devices'
        Config.singleton.devices.each(&:force_publish_all!)
      end

      def unhandled_topic(topic)
        AppLogger.warn "Unknown command handler for #{topic}"
      end

      def online_message?(message)
        message == 'online'
      end

      def offline_message?(message)
        !online_message?(message)
      end

      def check_and_publish_availability(message)
        @now_online = online_message?(message)
        force_publish_online! if @was_offline && @now_online
        @was_offline = offline_message(message)
      end

      def handle(topic, handlers, message, with_update: false)
        Thread.new do
          handlers.each do |handler|
            state_to_update = handler[:state]
            adapted_info = message
            if handler[:entity_adapter_method].present?
              adapted_info = entity_adapted_info(message, **handler)
            elsif handler[:device_adapter_method].present?
              adapted_info = device_adapted_info(message, **handler)
            end
            call_handler_of_entity(**handler, with_update:, adapted_info:, state_to_update:)
          end
        rescue StandardError => e
          AppLogger.exception(e, context: "Exception in handler for topic #{topic}")
          exit(1)
        end
      end

      def entity_adapted_info(message, entity:, entity_adapter_method:, **_)
        entity.send(entity_adapter_method.to_s, message)
      end

      def device_adapted_info(message, device:, device_adapter_method:, entity: nil, **_)
        method_object = device.method(device_adapter_method)
        if method_object.parameters.length == 1
          device.send(device_adapter_method.to_s, message)
        else
          device.send(device_adapter_method.to_s, message, entity)
        end
      end

      def call_handler_of_entity(with_update:, adapted_info:, state_to_update:, entity: nil, **_)
        return if entity.blank?

        method_name = with_update ? "#{state_to_update}_with_update=" : "#{state_to_update}="
        entity.send(method_name, adapted_info)
      end
    end
  end
end
