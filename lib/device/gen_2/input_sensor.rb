module Device
  module Gen2
    module InputSensor
      KEYS = %i[state].freeze
      SENSOR_OPTIONS = lambda { |device_name, manufacturer_name, index|
        {
          configuration_url: ->(entity) { "http://#{entity.device.ip_address}" },
          entity_constructor: ->(device) { { unique_id: "#{device.unique_id}-input-#{index}" } },
          hw_version: "#{Config::BLIGHVID.capitalize}-#{device_name}",
          identifiers: ->(entity) { [entity.device.unique_id] },
          json_attributes_topic: lambda { |entity|
            "#{Config::BLIGHVID}/#{entity.device.unique_id}/input/attributes/#{index}"
          },
          listener_topics: [state: "status/input:#{index}", state_adapter_method: :input_adapter_method],
          manufacturer: manufacturer_name,
          model: device_name,
          name: 'Input',
          state_topic: ->(entity) { "#{Config::BLIGHVID}/#{entity.device.unique_id}/input/#{index}" }
        }
      }

      def state_update_callback(message)
        message
      end

      def input_adapter_method(message)
        json_message = hashified_message(message)
        json_message.dig(*InputSensor::KEYS)
      end
    end
  end
end
