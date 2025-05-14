module Components
  module Gen2
    module LightSensor
      KEYS = %i[output].freeze
      BRIGTHNESS_KEYS = %i[brightness].freeze
      SENSOR_OPTIONS = lambda { |device_name, manufacturer_name, index, _state_key|
        {
          brightness_scale: 100,
          brightness_callback: :brightness_update_callback,
          brightness_command_topic: ->(entity) { "#{entity.device.publish_topic_prefix}/brightness-command/#{index}" },
          brightness_topic: ->(entity) { "#{entity.device.publish_topic_prefix}/light/#{index}/brightness" },
          callback: :state_update_callback,
          command_topic: ->(entity) { "#{entity.device.publish_topic_prefix}/command/#{index}" },
          configuration_url: ->(entity) { "http://#{entity.device.ip_address}" },
          entity_constructor: ->(device) { { unique_id: "#{device.unique_id}-light-#{index}", initial_value: 0.0 } },
          hw_version: "#{Config::BLIGHVID.capitalize}-#{device_name}",
          identifiers: ->(entity) { [entity.device.unique_id] },
          json_attributes_topic: lambda { |entity|
            "#{Config::BLIGHVID}/#{entity.device.unique_id}/light/attributes/#{index}"
          },
          listener_topics: [{ state: "status/light:#{index}", state_adapter_method: :light_adapter_method },
                            { brightness: "light/#{index}", brightness_adapter_method: :brightness_adapter_method }],
          manufacturer: manufacturer_name,
          model: device_name,
          name: 'Light',
          state_topic: ->(entity) { "#{Config::BLIGHVID}/#{entity.device.unique_id}/light/#{index}" }
        }
      }

      def light_adapter_method(message)
        json_message = hashified_message(message)
        json_message.dig(*LightSensor::KEYS)
      end

      def brightness_adapter_method(message)
        json_message = hashified_message(message)
        json_message.dig(*LightSensor::BRIGHTNESS_KEYS)
      end

      def brightness_update_callback(message) = message

      def state_update_callback(message) = message

      def post_state_update(entity_name)
        return unless entity_name.to_s.downcase.start_with?('light')

        state = instance_variable_get("@#{entity_name.parameterize.underscore}").state&.downcase
        brightness = instance_variable_get("@#{entity_name.parameterize.underscore}").brightness
        publish_client.update_light_state(state, brightness)
      end
    end
  end
end
