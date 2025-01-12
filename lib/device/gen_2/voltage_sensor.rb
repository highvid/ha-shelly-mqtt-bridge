module Device
  module Gen2
    module VoltageSensor
      KEYS = %i[voltage].freeze
      SENSOR_OPTIONS = lambda { |device_name, manufacturer_name|
        {
          configuration_url: ->(entity) { "http://#{entity.device.ip_address}" },
          device_class: 'voltage',
          entity_constructor: ->(device) { { unique_id: "#{device.unique_id}-voltage", initial_value: 0.0 } },
          hw_version: "#{Config::BLIGHVID.capitalize}-#{device_name}",
          identifiers: ->(entity) { [entity.device.unique_id] },
          json_attributes_topic: ->(entity) { "#{Config::BLIGHVID}/#{entity.unique_id}/attributes" },
          listener_topics: [state: 'status/switch:0', state_adapter_method: :voltage_adapter_method],
          manufacturer: manufacturer_name,
          model: device_name,
          name: 'Voltage',
          number_type: :to_f,
          state_topic: ->(entity) { "#{Config::BLIGHVID}/#{entity.device.unique_id}/voltage" },
          suggested_display_precision: 2,
          unit_of_measurement: 'V'
        }
      }

      def voltage_adapter_method(message)
        json_message = hashified_message(message)
        json_message.dig(*VoltageSensor::KEYS)
      end
    end
  end
end
