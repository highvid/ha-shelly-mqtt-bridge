module Device
  module Gen2
    module PowerSensor
      KEYS = %i[apower].freeze
      SENSOR_OPTIONS = lambda { |device_name, manufacturer_name|
        {
          configuration_url: ->(entity) { "http://#{entity.device.ip_address}" },
          device_class: 'power',
          entity_constructor: ->(device) { { unique_id: "#{device.unique_id}-power", initial_value: 0.0 } },
          hw_version: "#{Config::BLIGHVID.capitalize}-#{device_name}",
          identifiers: ->(entity) { [entity.device.unique_id] },
          json_attributes_topic: ->(entity) { "#{Config::BLIGHVID}/#{entity.unique_id}/attributes" },
          listener_topics: [state: 'status/switch:0', state_adapter_method: :power_adapter_method],
          manufacturer: manufacturer_name,
          model: device_name,
          name: 'Power',
          number_type: :to_f,
          state_topic: ->(entity) { "#{Config::BLIGHVID}/#{entity.device.unique_id}/power" },
          suggested_display_precision: 2,
          unit_of_measurement: 'W'
        }
      }

      def power_adapter_method(message)
        json_message = hashified_message(message)
        json_message.dig(*PowerSensor::KEYS)
      end
    end
  end
end
