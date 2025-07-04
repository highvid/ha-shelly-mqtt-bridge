module Mqtt
  module Support
    module Listenable
      attr_reader :initialised_devices

      def threads
        super + [thread_for_state_listeners, thread_for_command_listeners]
      end

      def thread_for_state_listeners
        @thread_for_state_listeners ||= Thread.new do
          relay_mqtt.get do |topic, message|
            AppLogger.debug "Got message from topic #{topic} -> #{message}"
            if aggregated_topics[topic].present?
              handle(topic, aggregated_topics[topic], message)
            elsif topic =~ %r{shellies/.+/announce}
              discover(topic, message)
            else
              unhandled_topic(topic)
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
            elsif topic == Mqtt::Subscriber::HOME_ASSISTANT_UPDATES_TOPIC
              check_and_publish_availability(message)
            else
              unhandled_command_topic(topic)
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

      def discover(topic, message)
        @initialised_devices ||= []
        mapper = Device::Mapper.new(topic, message)
        return if @initialised_devices.include?(mapper.unique_id)

        AppLogger.info("Found device #{mapper.unique_id} (#{initialised_devices.length + 1})")
        subscribe_to_device!(mapper.device)
        @initialised_devices << mapper.unique_id
      end

      def subscribe_to_device!(device)
        subscribe_to_aggregated_topics(device)
        subscribe_to_aggregated_command_topics(device)
        Config.singleton.add_device(device)
      end

      def subscribe_to_aggregated_topics(device)
        relay_mqtt.subscribe(device.all_relay_topic_listeners.keys)
      end

      def subscribe_to_aggregated_command_topics(device)
        home_assistant_mqtt.subscribe(device.all_command_topic_listeners.keys)
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
