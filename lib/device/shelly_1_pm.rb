module Device
  class Shelly1Pm < Shelly1
    DEVICE = 'Shelly1PM'.freeze

    sensor  :energy,
            configuration_url: ->(entity) { "http://#{entity.device.ip_address}" },
            device_class: 'energy',
            entity_constructor: lambda { |device, _entity_name|
              { unique_id: "#{device.unique_id}-energy", initial_value: 0.0 }
            },
            hw_version: "#{Config::BLIGHVID.capitalize}-#{DEVICE}",
            identifiers: ->(entity) { [entity.device.unique_id] },
            json_attributes_topic: ->(entity) { "#{Config::BLIGHVID}/#{entity.unique_id}/attributes" },
            listener_topics: 'relay/0/energy',
            manufacturer: MANUFACTURER,
            model: DEVICE,
            name: 'Energy',
            number_type: :to_w_h,
            state_class: 'total_increasing',
            state_topic: ->(entity) { "#{Config::BLIGHVID}/#{entity.device.unique_id}/energy" },
            suggested_display_precision: 2,
            unit_of_measurement: 'Wh'
    sensor  :power,
            configuration_url: ->(entity) { "http://#{entity.device.ip_address}" },
            device_class: 'power',
            entity_constructor: lambda { |device, _entity_name|
              { unique_id: "#{device.unique_id}-power", initial_value: 0.0 }
            },
            hw_version: "#{Config::BLIGHVID.capitalize}-#{DEVICE}",
            identifiers: ->(entity) { [entity.device.unique_id] },
            json_attributes_topic: ->(entity) { "#{Config::BLIGHVID}/#{entity.unique_id}/attributes" },
            listener_topics: 'relay/0/power',
            manufacturer: MANUFACTURER,
            model: DEVICE,
            name: 'Power',
            number_type: :to_f,
            state_topic: ->(entity) { "#{Config::BLIGHVID}/#{entity.device.unique_id}/power" },
            suggested_display_precision: 2,
            unit_of_measurement: 'W'
    sensor  :temperature,
            configuration_url: ->(entity) { "http://#{entity.device.ip_address}" },
            device_class: 'temperature',
            entity_constructor: ->(device) { { unique_id: "#{device.unique_id}-temperature", initial_value: 0.0 } },
            hw_version: "#{Config::BLIGHVID.capitalize}-#{DEVICE}",
            identifiers: ->(entity) { [entity.device.unique_id] },
            json_attributes_topic: ->(entity) { "#{Config::BLIGHVID}/#{entity.unique_id}/attributes" },
            listener_topics: [{ state: 'temperature', state_adapter_method: :float_adapter }],
            manufacturer: MANUFACTURER,
            model: DEVICE,
            name: 'Temperature',
            number_type: :to_f,
            state_topic: ->(entity) { "#{Config::BLIGHVID}/#{entity.device.unique_id}/temperature" },
            suggested_display_precision: 2,
            unit_of_measurement: '°C'

    def update_entities_states(json_message)
      super
      @temperature.state = json_message[:temperature]
      @power.state = json_message[:meters][0][:power]
      @energy.state = json_message[:meters][0][:total]
    end
  end
end
