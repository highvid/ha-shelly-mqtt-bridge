module Device
  class Shelly25
    include Publishable
    DEVICE = 'Shelly25'
    binary_sensor :input_0, :input_1,
      configuration_url: -> (entity) { "http://#{entity.device.ip_address}" },
      entity_constructor: -> (device, entity_name) { { unique_id: "#{device.unique_id}-input-#{entity_name[-1]}" } },
      hw_version: "#{Config::BLIGHVID.capitalize}-#{DEVICE}",
      identifiers: -> (entity) { [entity.device.unique_id] },
      json_attributes_topic: -> (entity) { "#{Config::BLIGHVID}/#{entity.unique_id}/attributes" },
      listener_topics: ->(entity) { "input/#{entity.name[-1]}" },
      manufacturer: "#{Config::BLIGHVID}",
      model: DEVICE,
      name: -> (entity) { "Input #{entity.unique_id[-1]}"},
      state_topic: -> (entity) { "#{Config::BLIGHVID}/#{entity.device.unique_id}/input/#{entity.name[-1]}" }
    sensor :energy_0, :energy_1,
      configuration_url: -> (entity) { "http://#{entity.device.ip_address}" },
      device_class: 'energy',
      entity_constructor: -> (device, entity_name) { { unique_id: "#{device.unique_id}-energy-#{entity_name[-1]}", initial_value: 0.0 } },
      hw_version: "#{Config::BLIGHVID.capitalize}-#{DEVICE}",
      identifiers: -> (entity) { [entity.device.unique_id] },
      json_attributes_topic: -> (entity) { "#{Config::BLIGHVID}/#{entity.unique_id}/attributes" },
      listener_topics: ->(entity) { "relay/#{entity.name[-1]}/energy" },
      manufacturer: "#{Config::BLIGHVID}",
      model: DEVICE,
      name: -> (entity) { "Energy #{entity.unique_id[-1]}"},
      number_type: :to_w_h,
      state_class: 'total_increasing',
      state_topic: -> (entity) { "#{Config::BLIGHVID}/#{entity.device.unique_id}/#{entity.unique_id[-1]}/energy" },
      suggested_display_precision: 2,
      unit_of_measurement: 'Wh'
    sensor :power_0, :power_1,
      configuration_url: -> (entity) { "http://#{entity.device.ip_address}" },
      device_class: 'power',
      entity_constructor: -> (device, entity_name) { { unique_id: "#{device.unique_id}-power-#{entity_name[-1]}", initial_value: 0.0 } },
      hw_version: "#{Config::BLIGHVID.capitalize}-#{DEVICE}",
      identifiers: -> (entity) { [entity.device.unique_id] },
      json_attributes_topic: -> (entity) { "#{Config::BLIGHVID}/#{entity.unique_id}/attributes" },
      listener_topics: ->(entity) { "relay/#{entity.name[-1]}/power" },
      manufacturer: "#{Config::BLIGHVID}",
      model: DEVICE,
      name: -> (entity) { "Power #{entity.unique_id[-1]}"},
      number_type: :to_f,
      state_topic: -> (entity) { "#{Config::BLIGHVID}/#{entity.device.unique_id}/#{entity.unique_id[-1]}/power" },
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
    sensor :voltage,
      configuration_url: -> (entity) { "http://#{entity.device.ip_address}" },
      device_class: 'voltage',
      entity_constructor: -> (device) { { unique_id: "#{device.unique_id}-voltage", initial_value: 0.0 } },
      hw_version: "#{Config::BLIGHVID.capitalize}-#{DEVICE}",
      identifiers: -> (entity) { [entity.device.unique_id] },
      json_attributes_topic: -> (entity) { "#{Config::BLIGHVID}/#{entity.unique_id}/attributes" },
      listener_topics: [{ state: 'voltage', state_adapter_method: :float_adapter }],
      manufacturer: "#{Config::BLIGHVID}",
      model: DEVICE,
      name: 'Voltage',
      number_type: :to_f,
      state_topic: -> (entity) { "#{Config::BLIGHVID}/#{entity.device.unique_id}/voltage" },
      suggested_display_precision: 2,
      unit_of_measurement: 'V'

    switch :relay_0, :relay_1,
      callback: :state_update_callback,
      command_topic: -> (entity) { "#{entity.device.publish_topic_prefix}/command/#{entity.unique_id[-1]}" },
      configuration_url: -> (entity) { "http://#{entity.device.ip_address}" },
      entity_constructor: ->(device, entity_name) { { unique_id: "#{device.unique_id}-relay-#{entity_name[-1]}", initial_value: 'OFF' } },
      hw_version: "#{Config::BLIGHVID.capitalize}1.0",
      identifiers: -> (entity) { [entity.device.unique_id] },
      json_attributes_topic: -> (entity) { "#{Config::BLIGHVID}/#{entity.unique_id}/attributes" },
      listener_topics: ->(entity) { "relay/#{entity.name[-1]}" },
      manufacturer: "#{Config::BLIGHVID}",
      model: DEVICE,
      name: -> (entity) { "Relay #{entity.unique_id[-1]}"},
      state_topic: -> (entity) { "#{entity.device.publish_topic_prefix}/relay/#{entity.unique_id[-1]}" }
    
    listener_topics 'info', update_method: :update_info

    def initialize(**options)
      assign!(options)
      @announce_topic = "shellies/#{unique_id}/command"
      @announce_payload = 'announce'
      @announce_listen_topic = "shellies/#{unique_id}/info"
      @announce_method_adapter = :announce_message_process
      @post_announce_action = :post_init
      init!(options)
    end

    def announce_message_process(message)
      json_message = JSON.parse(message).deep_symbolize_keys unless message.is_a?(Hash)
      @ip_address = json_message[:wifi_sta][:ip]
      @device_id = json_message[:mac]
    end

    def post_init(message)
      update_info(message)
    end

    def update_info(message)
      $LOGGER.info "Update info #{name}"
      json_message = JSON.parse(message).deep_symbolize_keys unless message.is_a?(Hash)
      @ip_address = json_message[:wifi_sta][:ip]
      @device_id = json_message[:mac]
      @relay_0.state = json_message[:relays][0][:ison]
      @relay_1.state = json_message[:relays][1][:ison]
      @input_0.state = json_message[:inputs][0][:input]
      @input_1.state = json_message[:inputs][1][:input]
      @temperature.state = json_message[:tmp][:tC]
      @voltage.state = json_message[:voltage]
      @power_0.state = json_message[:meters][0][:power]
      @power_1.state = json_message[:meters][1][:power]
    end

    def float_adapter(value)
      value.to_f
    end

    def integer_adapter(value)
      value.to_i
    end

    def http_client
      @http_client ||= HttpClient::Shelly25.new(ip_address)
    end

    def post_state_update(entity_name)
      relay = instance_variable_get("@relay_#{entity_name[-1]}")
      if %w[relay\ 0 relay\ 1].include?(entity_name.to_s.downcase)
        http_client.update_relay_state(entity_name[-1], relay.state&.downcase)
      end
    end

    def state_update_callback(message)
      message
    end
  end
end
