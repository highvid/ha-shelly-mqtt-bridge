module Device
  module Gen2
    module TemperatureSensor
      KEYS = %i[temperature tC].freeze
      SENSOR_OPTIONS = lambda { |device_name, manufacturer_name, index|
        {
          configuration_url: ->(entity) { "http://#{entity.device.ip_address}" },
          device_class: 'temperature',
          entity_constructor: lambda { |device|
            { unique_id: "#{device.unique_id}-temperature-#{index}", initial_value: 0.0 }
          },
          hw_version: "#{Config::BLIGHVID.capitalize}-#{device_name}",
          identifiers: ->(entity) { [entity.device.unique_id] },
          json_attributes_topic: lambda { |entity|
            "#{Config::BLIGHVID}/#{entity.device.unique_id}/temperature/attributes/#{index}"
          },
          listener_topics: [state: "status/switch:#{index}", state_adapter_method: :temperature_adapter_method],
          manufacturer: manufacturer_name,
          model: device_name,
          name: 'Temperature',
          number_type: :to_f,
          state_topic: ->(entity) { "#{Config::BLIGHVID}/#{entity.device.unique_id}/temperature/#{index}" },
          suggested_display_precision: 2,
          unit_of_measurement: '°C'
        }
      }

      def temperature_adapter_method(message)
        json_message = hashified_message(message)
        json_message.dig(*TemperatureSensor::KEYS)
      end
    end
  end
end
