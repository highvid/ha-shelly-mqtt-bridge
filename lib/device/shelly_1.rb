module Device
  class Shelly1
    DEVICE = 'Shelly1'
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
    
    def initialize(**options)
      assign!(options)
      @announce_topic = generate_topic('command')
      @announce_payload = 'announce'
      @announce_listen_topic = generate_topic('info')
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
      @output.state = json_message[:relays][0][:ison]
      @input.state = json_message[:inputs][0][:input]
    end

    def post_state_update(entity_name)
      http_client.update_relay_state(@output.state&.downcase) if entity_name.to_s == 'Output'
    end

    def state_update_callback(message)
      message
    end

    def http_client
      @http_client ||= HttpClient::Shelly1.new(ip_address)
    end

    def float_adapter(value)
      value.to_f
    end

    def integer_adapter(value)
      value.to_i
    end
  end
end
