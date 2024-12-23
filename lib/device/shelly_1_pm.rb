module Device
  class Shelly1Pm
    DEVICE = 'Shelly1PM'
    include Publishable
    binary_sensor :input,
      configuration_url: -> (entity) { "http://#{entity.device.ip_address}" },
      entity_constructor: -> (device, _entity_name) { { unique_id: "#{device.unique_id}-input" } },
      hw_version: "#{Config::BLIGHVID.capitalize}-#{DEVICE}",
      identifiers: -> (entity) { [entity.device.unique_id] },
      json_attributes_topic: -> (entity) { "#{Config::BLIGHVID}/#{entity.unique_id}/attributes" },
      listener_topics: 'input/0',
      manufacturer: "#{Config::BLIGHVID}",
      model: DEVICE,
      name: 'Input',
      state_topic: -> (entity) { "#{Config::BLIGHVID}/#{entity.device.unique_id}/input" }
    switch :output,
      callback: :state_update_callback,
      command_topic: -> (entity) { "#{entity.device.publish_topic_prefix}/command" },
      configuration_url: -> (entity) { "http://#{entity.device.ip_address}" },
      entity_constructor: ->(device) { { unique_id: "#{device.unique_id}-relay", initial_value: 'OFF' } },
      hw_version: "#{Config::BLIGHVID.capitalize}-#{DEVICE}",
      identifiers: -> (entity) { [entity.device.unique_id] },
      json_attributes_topic: -> (entity) { "#{Config::BLIGHVID}/#{entity.unique_id}/attributes" },
      listener_topics: 'relay/0',
      manufacturer: "#{Config::BLIGHVID}",
      model: DEVICE,
      name: 'Output',
      state_topic: -> (entity) { "#{entity.device.publish_topic_prefix}/output" }
    sensor :energy,
      configuration_url: -> (entity) { "http://#{entity.device.ip_address}" },
      device_class: 'energy',
      entity_constructor: -> (device, entity_name) { { unique_id: "#{device.unique_id}-energy", initial_value: 0.0 } },
      hw_version: "#{Config::BLIGHVID.capitalize}-#{DEVICE}",
      identifiers: -> (entity) { [entity.device.unique_id] },
      json_attributes_topic: -> (entity) { "#{Config::BLIGHVID}/#{entity.unique_id}/attributes" },
      listener_topics: 'relay/0/energy',
      manufacturer: "#{Config::BLIGHVID}",
      model: DEVICE,
      name: 'Energy',
      number_type: :to_w_h,
      state_class: 'total_increasing',
      state_topic: -> (entity) { "#{Config::BLIGHVID}/#{entity.device.unique_id}/energy" },
      suggested_display_precision: 2,
      unit_of_measurement: 'Wh'
    sensor :power,
      configuration_url: -> (entity) { "http://#{entity.device.ip_address}" },
      device_class: 'power',
      entity_constructor: -> (device, entity_name) { { unique_id: "#{device.unique_id}-power", initial_value: 0.0 } },
      hw_version: "#{Config::BLIGHVID.capitalize}-#{DEVICE}",
      identifiers: -> (entity) { [entity.device.unique_id] },
      json_attributes_topic: -> (entity) { "#{Config::BLIGHVID}/#{entity.unique_id}/attributes" },
      listener_topics: 'relay/0/power',
      manufacturer: "#{Config::BLIGHVID}",
      model: DEVICE,
      name: 'Power',
      number_type: :to_f,
      state_topic: -> (entity) { "#{Config::BLIGHVID}/#{entity.device.unique_id}/power" },
      suggested_display_precision: 2,
      unit_of_measurement: 'W'
    sensor :temperature,
      configuration_url: -> (entity) { "http://#{entity.device.ip_address}" },
      device_class: 'temperature',
      entity_constructor: -> (device) { { unique_id: "#{device.unique_id}-temperature", initial_value: 0.0 } },
      hw_version: "#{Config::BLIGHVID.capitalize}-#{DEVICE}",
      identifiers: -> (entity) { [entity.device.unique_id] },
      json_attributes_topic: -> (entity) { "#{Config::BLIGHVID}/#{entity.unique_id}/attributes" },
      listener_topics: [{ state: 'temperature', state_adapter_method: :float_adapter }],
      manufacturer: "#{Config::BLIGHVID}",
      model: DEVICE,
      name: 'Temperature',
      number_type: :to_f,
      state_topic: -> (entity) { "#{Config::BLIGHVID}/#{entity.device.unique_id}/temperature" },
      suggested_display_precision: 2,
      unit_of_measurement: '°C'
    update :sw_version,
      callback: :call_to_update,
      command_topic: -> (entity) { "#{entity.device.publish_topic_prefix}/update" },
      device_class: 'firmware',
      configuration_url: -> (entity) { "http://#{entity.device.ip_address}" },
      entity_constructor: ->(device) { { unique_id: "#{device.unique_id}-sw-version", initial_value: nil  } },
      hw_version: "#{Config::BLIGHVID.capitalize}-#{DEVICE}",
      identifiers: -> (entity) { [entity.device.unique_id] },
      json_attributes_topic: -> (entity) { "#{Config::BLIGHVID}/#{entity.unique_id}/attributes" },
      listener_topics: [ { state: 'info', state_adapter_method: :sw_version_adapter } ],
      manufacturer: "#{Config::BLIGHVID}",
      model: DEVICE,
      name: 'Firmware',
      payload_install: 'update',
      platform: 'update',
      state_topic: -> (entity) { "#{entity.device.publish_topic_prefix}/firmware" }
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
      $LOGGER.info "Update info #{name}"
      json_message = JSON.parse(message).deep_symbolize_keys unless message.is_a?(Hash)
      @ip_address = json_message[:wifi_sta][:ip]
      @device_id = json_message[:mac]
      @output.state = json_message[:relays][0][:ison]
      @input.state = json_message[:inputs][0][:input]
      @temperature.state = json_message[:temperature]
      @power.state = json_message[:meters][0][:power]
      @energy.state = json_message[:meters][0][:total]
      $LOGGER.info("Setting current version to #{json_message[:update][:old_version]}")
      @sw_version.latest_version = json_message[:update][:new_version]
      @sw_version.state = json_message[:update][:old_version]
      $LOGGER.info("Setting latest version to #{@sw_version.latest_version}")
    end

    def post_state_update(entity_name)
      http_client.update_relay_state(@output.state&.downcase) if entity_name.to_s == 'Output'
    end

    def sw_version_adapter(message)
      json_message = JSON.parse(message).deep_symbolize_keys unless message.is_a?(Hash)
      @sw_version.in_progress = %w[updating].include?(json_message[:update][:status])
      @sw_version.update_percentage = @sw_version.in_progress ? 0.0 : nil
      json_message[:update][:old_version]
    end

    def call_to_update(message)
      if message == 'update'
        $LOGGER.info "Updating #{name} to latest"
        mqtt_client.publish("shellies/#{unique_id}/command", 'update_fw')
        @sw_version.in_progress = true
        @sw_version.update_percentage = 0.0
      end
    end

    def mqtt_client
      Config.singleton.relay_mqtt
    end

    def state_update_callback(message)
      message
    end

    def http_client
      @http_client ||= HttpClient::Shelly1Pm.new(ip_address)
    end

    def float_adapter(value)
      value.to_f
    end

    def integer_adapter(value)
      value.to_i
    end
  end
end
