module Device
  class ShellyPlus2Pm
    DEVICE = 'ShellyPlus2PM'
    include Publishable
    binary_sensor :input_0, :input_1,
      configuration_url: -> (entity) { "http://#{entity.device.ip_address}" },
      entity_constructor: -> (device, entity_name) { { unique_id: "#{device.unique_id}-input-#{entity_name[-1]}" } },
      hw_version: "#{Config::BLIGHVID.capitalize}-#{DEVICE}",
      identifiers: -> (entity) { [entity.device.unique_id] },
      json_attributes_topic: -> (entity) { "#{Config::BLIGHVID}/#{entity.unique_id}/attributes" },
      listener_topics: [state: -> (entity) { "status/input:#{entity.name[-1]}" }, state_adapter_method: :input_adapter_method],
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
      listener_topics: [state: -> (entity) { "status/switch:#{entity.name[-1]}" }, state_adapter_method: :energy_adapter_method],
      manufacturer: "#{Config::BLIGHVID}",
      model: DEVICE,
      name: -> (entity) { "Energy #{entity.unique_id[-1]}"},
      number_type: :to_w_h,
      state_class: 'total_increasing',
      state_topic: -> (entity) { "#{Config::BLIGHVID}/#{entity.device.unique_id}/energy/#{entity.name[-1]}" },
      suggested_display_precision: 2,
      unit_of_measurement: 'Wh'
    sensor :power_0, :power_1,
      configuration_url: -> (entity) { "http://#{entity.device.ip_address}" },
      device_class: 'power',
      entity_constructor: -> (device, entity_name) { { unique_id: "#{device.unique_id}-power-#{entity_name[-1]}", initial_value: 0.0 } },
      hw_version: "#{Config::BLIGHVID.capitalize}-#{DEVICE}",
      identifiers: -> (entity) { [entity.device.unique_id] },
      json_attributes_topic: -> (entity) { "#{Config::BLIGHVID}/#{entity.unique_id}/attributes" },
      listener_topics: [state: -> (entity) { "status/switch:#{entity.name[-1]}" }, state_adapter_method: :power_adapter_method],
      manufacturer: "#{Config::BLIGHVID}",
      model: DEVICE,
      name: -> (entity) { "Power #{entity.unique_id[-1]}"},
      number_type: :to_f,
      state_topic: -> (entity) { "#{Config::BLIGHVID}/#{entity.device.unique_id}/power/#{entity.name[-1]}" },
      suggested_display_precision: 2,
      unit_of_measurement: 'W'
    sensor :temperature_0, :temperature_1,
      configuration_url: -> (entity) { "http://#{entity.device.ip_address}" },
      device_class: 'temperature',
      entity_constructor: -> (device, entity_name) { { unique_id: "#{device.unique_id}-temperature-#{entity_name[-1]}", initial_value: 0.0 } },
      hw_version: "#{Config::BLIGHVID.capitalize}-#{DEVICE}",
      identifiers: -> (entity) { [entity.device.unique_id] },
      json_attributes_topic: -> (entity) { "#{Config::BLIGHVID}/#{entity.unique_id}/attributes" },
      listener_topics: [state: -> (entity) { "status/switch:#{entity.name[-1]}" }, state_adapter_method: :temperature_adapter_method],
      manufacturer: "#{Config::BLIGHVID}",
      model: DEVICE,
      name: -> (entity) { "Temperature #{entity.unique_id[-1]}"},
      number_type: :to_f,
      state_topic: -> (entity) { "#{Config::BLIGHVID}/#{entity.device.unique_id}/temperature/#{entity.name[-1]}" },
      suggested_display_precision: 2,
      unit_of_measurement: '°C'
    sensor :voltage_0, :voltage_1,
      configuration_url: -> (entity) { "http://#{entity.device.ip_address}" },
      device_class: 'voltage',
      entity_constructor: -> (device, entity_name) { { unique_id: "#{device.unique_id}-voltage-#{entity_name[-1]}", initial_value: 0.0 } },
      hw_version: "#{Config::BLIGHVID.capitalize}-#{DEVICE}",
      identifiers: -> (entity) { [entity.device.unique_id] },
      json_attributes_topic: -> (entity) { "#{Config::BLIGHVID}/#{entity.unique_id}/attributes" },
      listener_topics: [state: -> (entity) { "status/switch:#{entity.name[-1]}" }, state_adapter_method: :voltage_adapter_method],
      manufacturer: "#{Config::BLIGHVID}",
      model: DEVICE,
      name: -> (entity) { "Voltage #{entity.unique_id[-1]}"},
      number_type: :to_f,
      state_topic: -> (entity) { "#{Config::BLIGHVID}/#{entity.device.unique_id}/voltage/#{entity.name[-1]}" },
      suggested_display_precision: 2,
      unit_of_measurement: 'V'
    sensor :current_0, :current_1,
      configuration_url: -> (entity) { "http://#{entity.device.ip_address}" },
      device_class: 'current',
      entity_constructor: -> (device, entity_name) { { unique_id: "#{device.unique_id}-current-#{entity_name[-1]}", initial_value: 0.0 } },
      hw_version: "#{Config::BLIGHVID.capitalize}-#{DEVICE}",
      identifiers: -> (entity) { [entity.device.unique_id] },
      json_attributes_topic: -> (entity) { "#{Config::BLIGHVID}/#{entity.unique_id}/attributes" },
      listener_topics: [state: -> (entity) { "status/switch:#{entity.name[-1]}" }, state_adapter_method: :current_adapter_method],
      manufacturer: "#{Config::BLIGHVID}",
      model: DEVICE,
      name: -> (entity) { "Current #{entity.unique_id[-1]}"},
      number_type: :to_f,
      state_topic: -> (entity) { "#{Config::BLIGHVID}/#{entity.device.unique_id}/current/#{entity.name[-1]}" },
      suggested_display_precision: 2,
      unit_of_measurement: 'A'
    switch :output_0, :output_1,
      callback: :state_update_callback,
      command_topic: -> (entity) { "#{entity.device.publish_topic_prefix}/command/#{entity.name[-1]}" },
      configuration_url: -> (entity) { "http://#{entity.device.ip_address}" },
      entity_constructor: ->(device, entity_name) { { unique_id: "#{device.unique_id}-light-#{entity_name[-1]}", initial_value: 'OFF' } },
      hw_version: "#{Config::BLIGHVID.capitalize}-#{DEVICE}",
      identifiers: -> (entity) { [entity.device.unique_id] },
      json_attributes_topic: -> (entity) { "#{Config::BLIGHVID}/#{entity.unique_id}/attributes" },
      listener_topics: [state: -> (entity) { "status/switch:#{entity.name[-1]}" }, state_adapter_method: :output_adapter_method],
      manufacturer: "#{Config::BLIGHVID}",
      model: DEVICE,
      name: -> (entity) { "Output #{entity.unique_id[-1]}"},
      state_topic: -> (entity) { "#{entity.device.publish_topic_prefix}/output/#{entity.name[-1]}" }
    
    def initialize(**options)
      assign!(options)
      @announce_topic = generate_topic('command')
      @announce_payload = 'status_update'
      @announce_listen_topic = generate_topic('status')
      @announce_method_adapter = :announce_message_process
      @post_init_update_announce = :post_init
      init!(options)
    end

    def announce_message_process(message)
      json_message = JSON.parse(message).deep_symbolize_keys unless message.is_a?(Hash)
      @ip_address = json_message[:wifi][:sta_ip]
      @device_id = json_message[:sys][:mac]
    end

    def post_init(message)
      update_info(message)
    end

    def update_info(message)
      json_message = JSON.parse(message).deep_symbolize_keys unless message.is_a?(Hash)
      @ip_address = json_message[:wifi][:sta_ip]
      @device_id = json_message[:sys][:mac]
      @output_0.state = json_message[:'switch:0'][:output]
      @output_1.state = json_message[:'switch:1'][:output]
      @input_0.state = json_message[:'input:0'][:state]
      @input_1.state = json_message[:'input:1'][:state]
      @power_0.state = json_message[:'switch:0'][:apower]
      @power_1.state = json_message[:'switch:1'][:apower]
      @energy_0.state = json_message[:'switch:0'][:aenergy][:total]
      @energy_1.state = json_message[:'switch:1'][:aenergy][:total]
      @voltage_0.state = json_message[:'switch:0'][:voltage]
      @voltage_1.state = json_message[:'switch:1'][:voltage]
      @current_0.state = json_message[:'switch:0'][:current]
      @current_1.state = json_message[:'switch:1'][:current]
      @temperature_0.state = json_message[:'switch:0'][:temperature][:tC]
      @temperature_1.state = json_message[:'switch:1'][:temperature][:tC]
    end

    def post_state_update(entity_name)
      output = instance_variable_get("@output_#{entity_name[-1]}")
      if %w[output\ 0 output\ 1].include?(entity_name.to_s.downcase)
        http_client.update_output_state(entity_name[-1], output.state&.downcase)
      end
    end

    def input_adapter_method(message)
      json_message = JSON.parse(message).deep_symbolize_keys unless message.is_a?(Hash)
      json_message[:state]
    end

    def output_adapter_method(message)
      json_message = JSON.parse(message).deep_symbolize_keys unless message.is_a?(Hash)
      json_message[:output]
    end

    def temperature_adapter_method(message)
      json_message = JSON.parse(message).deep_symbolize_keys unless message.is_a?(Hash)
      json_message[:temperature][:tC]
    end

    def power_adapter_method(message)
      json_message = JSON.parse(message).deep_symbolize_keys unless message.is_a?(Hash)
      json_message[:apower]
    end

    def energy_adapter_method(message)
      json_message = JSON.parse(message).deep_symbolize_keys unless message.is_a?(Hash)
      json_message[:aenergy][:total]
    end

    def current_adapter_method(message)
      json_message = JSON.parse(message).deep_symbolize_keys unless message.is_a?(Hash)
      json_message[:current]
    end

    def voltage_adapter_method(message)
      json_message = JSON.parse(message).deep_symbolize_keys unless message.is_a?(Hash)
      json_message[:"voltage"]
    end

    def state_update_callback(message)
      message
    end

    def http_client
      @http_client ||= HttpClient::ShellyPlus2Pm.new(ip_address)
    end

    def float_adapter(value)
      value.to_f
    end

    def integer_adapter(value)
      value.to_i
    end
  end
end