module Device
  module Gen2
    module EnergySensor
      KEYS = %i[aenergy total].freeze
      SENSOR_OPTIONS = lambda { |device_name, manufacturer_name, index|
        {
          configuration_url: ->(entity) { "http://#{entity.device.ip_address}" },
          device_class: 'energy',
          entity_constructor: ->(device) { { unique_id: "#{device.unique_id}-energy-#{index}", initial_value: 0.0 } },
          hw_version: "#{Config::BLIGHVID.capitalize}-#{device_name}",
          identifiers: ->(entity) { [entity.device.unique_id] },
          json_attributes_topic: lambda { |entity|
            "#{Config::BLIGHVID}/#{entity.device.unique_id}/energy/attributes/#{index}"
          },
          listener_topics: [state: "status/switch:#{index}", state_adapter_method: :energy_adapter_method],
          manufacturer: manufacturer_name,
          model: device_name,
          name: 'Energy',
          number_type: :to_w_h,
          state_class: 'total_increasing',
          state_topic: ->(entity) { "#{Config::BLIGHVID}/#{entity.device.unique_id}/energy/#{index}" },
          suggested_display_precision: 2,
          unit_of_measurement: 'Wh'
        }
      }

      def energy_adapter_method(message)
        json_message = hashified_message(message)
        json_message.dig(*EnergySensor::KEYS)
      end
    end
  end
end
