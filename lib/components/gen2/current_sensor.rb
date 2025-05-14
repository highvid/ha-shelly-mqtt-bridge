module Components
  module Gen2
    module CurrentSensor
      KEYS = %i[current].freeze
      SENSOR_OPTIONS = lambda { |device_name, manufacturer_name, index, state_key|
        {
          configuration_url: ->(entity) { "http://#{entity.device.ip_address}" },
          device_class: 'current',
          entity_constructor: ->(device) { { unique_id: "#{device.unique_id}-current-#{index}", initial_value: 0.0 } },
          hw_version: "#{Config::BLIGHVID.capitalize}-#{device_name}",
          identifiers: ->(entity) { [entity.device.unique_id] },
          json_attributes_topic: lambda { |entity|
            "#{Config::BLIGHVID}/#{entity.device.unique_id}/current/attributes/#{index}"
          },
          listener_topics: [state: "status/#{state_key}:#{index}", state_adapter_method: :current_adapter_method],
          manufacturer: manufacturer_name,
          model: device_name,
          name: 'Current',
          number_type: :to_f,
          state_topic: ->(entity) { "#{Config::BLIGHVID}/#{entity.device.unique_id}/current/#{index}" },
          suggested_display_precision: 2,
          unit_of_measurement: 'A'
        }
      }

      def current_adapter_method(message)
        json_message = hashified_message(message)
        json_message.dig(*CurrentSensor::KEYS)
      end
    end
  end
end
