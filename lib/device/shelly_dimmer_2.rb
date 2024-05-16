module Device
  class ShellyDimmer2
    DEVICE = 'ShellyDimmer2'
    include Publishable
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
    sensor :output_energy,
      configuration_url: -> (entity) { "http://#{entity.device.ip_address}" },
      device_class: 'energy',
      entity_constructor: -> (device) { { unique_id: "#{device.unique_id}-energy", initial_value: 0.0 } },
      hw_version: "#{Config::BLIGHVID.capitalize}-#{DEVICE}",
      identifiers: -> (entity) { [entity.device.unique_id] },
      json_attributes_topic: -> (entity) { "#{Config::BLIGHVID}/#{entity.unique_id}/attributes" },
      listener_topics: [{ state: 'light/0/energy', state_adapter_method: :integer_adapter }],
      manufacturer: "#{Config::BLIGHVID}",
      model: DEVICE,
      name: "Energy",
      number_type: :to_i,
      state_topic: -> (entity) { "#{Config::BLIGHVID}/#{entity.device.unique_id}/energy" },
      unit_of_measurement: 'Wh'
    sensor :output_power,
      configuration_url: -> (entity) { "http://#{entity.device.ip_address}" },
      device_class: 'power',
      entity_constructor: -> (device) { { unique_id: "#{device.unique_id}-power", initial_value: 0.0 } },
      hw_version: "#{Config::BLIGHVID.capitalize}-#{DEVICE}",
      identifiers: -> (entity) { [entity.device.unique_id] },
      json_attributes_topic: -> (entity) { "#{Config::BLIGHVID}/#{entity.unique_id}/attributes" },
      listener_topics: [{ state: 'light/0/power', state_adapter_method: :float_adapter }],
      manufacturer: "#{Config::BLIGHVID}",
      model: DEVICE,
      name: 'Power',
      number_type: :to_f,
      state_topic: -> (entity) { "#{Config::BLIGHVID}/#{entity.device.unique_id}/power" },
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
      unit_of_measurement: '°C'

    light :output,
      brightness_scale: 100,
      brightness_callback: :brightness_update_callback,
      brightness_command_topic: -> (entity) { "#{entity.device.publish_topic_prefix}/brightness-command" },
      brightness_topic: -> (entity) { "#{entity.device.publish_topic_prefix}/light/0/brightness" },
      callback: :state_update_callback,
      command_topic: -> (entity) { "#{entity.device.publish_topic_prefix}/command" },
      configuration_url: -> (entity) { "http://#{entity.device.ip_address}" },
      entity_constructor: ->(device) { { unique_id: "#{device.unique_id}-light", initial_value: 'OFF' } },
      hw_version: "#{Config::BLIGHVID.capitalize}-#{DEVICE}",
      identifiers: -> (entity) { [entity.device.unique_id] },
      json_attributes_topic: -> (entity) { "#{Config::BLIGHVID}/#{entity.unique_id}/attributes" },
      listener_topics: [{ brightness: 'light/0/status', brightness_adapter_method: :brightness_adapt } , { state: 'light/0' }],
      manufacturer: "#{Config::BLIGHVID}",
      model: DEVICE,
      name: 'Light',
      state_topic: -> (entity) { "#{entity.device.publish_topic_prefix}/light/0" }
    
    listener_topics 'info', update_method: :update_info

    def initialize(**options)
      assign!(options)
      @announce_topic = "shellies/#{unique_id}/command"
      @announce_payload = 'announce'
      @announce_listen_topic = "shellies/#{unique_id}/info"
      @announce_method_adapter = :announce_message_process
      @post_init_update_announce = :post_init
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
      json_message = JSON.parse(message).deep_symbolize_keys unless message.is_a?(Hash)
      @ip_address = json_message[:wifi_sta][:ip]
      @device_id = json_message[:mac]
      @output.state = json_message[:lights][0][:ison]
      @output.brightness = json_message[:lights][0][:brightness]
      @input_0.state = json_message[:inputs][0][:input]
      @input_1.state = json_message[:inputs][1][:input]
      @temperature.state = json_message[:tmp][:tC]
    end

    def post_state_update(entity_name)
      http_client.update_light_state(@output.state&.downcase) if entity_name.to_s == 'Light'
    end

    def post_brightness_update(entity_name)
      http_client.update_brightness(@output.brightness) if entity_name.to_s == 'Light'
    end

    def state_update_callback(message)
      message
    end

    def brightness_update_callback(message)
      message
    end

    def http_client
      @http_client ||= HttpClient::ShellyDimmer2.new(ip_address)
    end

    def brightness_adapt(message)
      json_message = JSON.parse(message).deep_symbolize_keys
      json_message[:brightness].to_i
    end

    def float_adapter(value)
      value.to_f
    end

    def integer_adapter(value)
      value.to_i
    end
  end
end
