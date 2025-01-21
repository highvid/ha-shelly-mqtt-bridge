module Device
  class ShellyDimmer2
    DEVICE = 'ShellyDimmer2'.freeze
    MANUFACTURER = Config::BLIGHVID

    include Publishable
    prepend Gen1::DoubleInput
    prepend Gen1::Versionable

    sensor  :output_energy,
            configuration_url: ->(entity) { "http://#{entity.device.ip_address}" },
            device_class: 'energy',
            entity_constructor: ->(device) { { unique_id: "#{device.unique_id}-energy", initial_value: 0.0 } },
            hw_version: "#{Config::BLIGHVID.capitalize}-#{DEVICE}",
            identifiers: ->(entity) { [entity.device.unique_id] },
            json_attributes_topic: ->(entity) { "#{Config::BLIGHVID}/#{entity.unique_id}/attributes" },
            listener_topics: [{ state: 'light/0/energy', state_adapter_method: :integer_adapter }],
            manufacturer: Config::BLIGHVID.to_s,
            model: DEVICE,
            name: 'Energy',
            number_type: :to_w_h,
            state_class: 'total_increasing',
            state_topic: ->(entity) { "#{Config::BLIGHVID}/#{entity.device.unique_id}/energy" },
            suggested_display_precision: 2,
            unit_of_measurement: 'Wh'
    sensor  :output_power,
            configuration_url: ->(entity) { "http://#{entity.device.ip_address}" },
            device_class: 'power',
            entity_constructor: ->(device) { { unique_id: "#{device.unique_id}-power", initial_value: 0.0 } },
            hw_version: "#{Config::BLIGHVID.capitalize}-#{DEVICE}",
            identifiers: ->(entity) { [entity.device.unique_id] },
            json_attributes_topic: ->(entity) { "#{Config::BLIGHVID}/#{entity.unique_id}/attributes" },
            listener_topics: [{ state: 'light/0/power', state_adapter_method: :float_adapter }],
            manufacturer: Config::BLIGHVID.to_s,
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
            manufacturer: Config::BLIGHVID.to_s,
            model: DEVICE,
            name: 'Temperature',
            number_type: :to_f,
            state_topic: ->(entity) { "#{Config::BLIGHVID}/#{entity.device.unique_id}/temperature" },
            suggested_display_precision: 2,
            unit_of_measurement: '°C'

    light :output,
          brightness_scale: 100,
          brightness_callback: :brightness_update_callback,
          brightness_command_topic: ->(entity) { "#{entity.device.publish_topic_prefix}/brightness-command" },
          brightness_topic: ->(entity) { "#{entity.device.publish_topic_prefix}/light/0/brightness" },
          callback: :state_update_callback,
          command_topic: ->(entity) { "#{entity.device.publish_topic_prefix}/command" },
          configuration_url: ->(entity) { "http://#{entity.device.ip_address}" },
          entity_constructor: ->(device) { { unique_id: "#{device.unique_id}-light", initial_value: 'OFF' } },
          hw_version: "#{Config::BLIGHVID.capitalize}-#{DEVICE}",
          identifiers: ->(entity) { [entity.device.unique_id] },
          json_attributes_topic: ->(entity) { "#{Config::BLIGHVID}/#{entity.unique_id}/attributes" },
          listener_topics: [{ brightness: 'light/0/status', brightness_adapter_method: :brightness_adapt },
                            { state: 'light/0' }],
          manufacturer: Config::BLIGHVID.to_s,
          model: DEVICE,
          name: 'Light',
          state_topic: ->(entity) { "#{entity.device.publish_topic_prefix}/light/0" }

    listener_topics 'info', update_method: :update_info

    def initialize(**options)
      assign!(options)
      @announce_topics = {
        generate_topic('command') => [{
          listen_topic: generate_topic('info'),
          payload: 'announce',
          process: :announce_message_process,
          post_process: :update_info
        }]
      }
      init!(options)
    end

    def announce_message_process(message)
      json_message = JSON.parse(message).deep_symbolize_keys unless message.is_a?(Hash)
      @ip_address = json_message[:wifi_sta][:ip]
      @device_id = json_message[:mac]
    end

    def update_info(message)
      AppLogger.debug "Update info #{name}"
      json_message = JSON.parse(message).deep_symbolize_keys unless message.is_a?(Hash)
      @ip_address = json_message[:wifi_sta][:ip]
      @device_id = json_message[:mac]
      @output.state = json_message[:lights][0][:ison]
      @output.brightness = json_message[:lights][0][:brightness]
      @temperature.state = json_message[:tmp][:tC]
    end

    def post_state_update(entity_name)
      mqtt_client.update_light_state(@output.state&.downcase, @output.brightness) if entity_name.to_s == 'Light'
    end

    def post_brightness_update(entity_name)
      post_state_update(entity_name)
    end

    def state_update_callback(message)
      message
    end

    def brightness_update_callback(message)
      message
    end

    def brightness_adapt(message)
      json_message = JSON.parse(message).deep_symbolize_keys
      json_message[:brightness].to_i
    end
  end
end
