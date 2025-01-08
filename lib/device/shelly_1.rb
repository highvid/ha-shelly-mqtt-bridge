module Device
  class Shelly1
    DEVICE = 'Shelly1'.freeze
    include Publishable
    binary_sensor :input,
                  configuration_url: ->(entity) { "http://#{entity.device.ip_address}" },
                  entity_constructor: ->(device, _entity_name) { { unique_id: "#{device.unique_id}-input" } },
                  hw_version: "#{Config::BLIGHVID.capitalize}-#{DEVICE}",
                  identifiers: ->(entity) { [entity.device.unique_id] },
                  json_attributes_topic: ->(entity) { "#{Config::BLIGHVID}/#{entity.unique_id}/attributes" },
                  listener_topics: 'input/0',
                  manufacturer: Config::BLIGHVID.to_s,
                  model: DEVICE,
                  name: 'Input',
                  state_topic: ->(entity) { "#{Config::BLIGHVID}/#{entity.device.unique_id}/input" }
    switch :output,
           callback: :state_update_callback,
           command_topic: ->(entity) { "#{entity.device.publish_topic_prefix}/command" },
           configuration_url: ->(entity) { "http://#{entity.device.ip_address}" },
           entity_constructor: ->(device) { { unique_id: "#{device.unique_id}-relay", initial_value: 'OFF' } },
           hw_version: "#{Config::BLIGHVID.capitalize}-#{DEVICE}",
           identifiers: ->(entity) { [entity.device.unique_id] },
           json_attributes_topic: ->(entity) { "#{Config::BLIGHVID}/#{entity.unique_id}/attributes" },
           listener_topics: 'relay/0',
           manufacturer: Config::BLIGHVID.to_s,
           model: DEVICE,
           name: 'Output',
           state_topic: ->(entity) { "#{entity.device.publish_topic_prefix}/output" }
    update :sw_version,
           callback: :call_to_update,
           command_topic: ->(entity) { "#{entity.device.publish_topic_prefix}/update" },
           device_class: 'firmware',
           configuration_url: ->(entity) { "http://#{entity.device.ip_address}" },
           entity_constructor: ->(device) { { unique_id: "#{device.unique_id}-sw-version", initial_value: nil } },
           hw_version: "#{Config::BLIGHVID.capitalize}-#{DEVICE}",
           identifiers: ->(entity) { [entity.device.unique_id] },
           json_attributes_topic: ->(entity) { "#{Config::BLIGHVID}/#{entity.unique_id}/attributes" },
           listener_topics: [{ state: 'info', state_adapter_method: :sw_version_adapter }],
           manufacturer: Config::BLIGHVID.to_s,
           model: DEVICE,
           name: 'Firmware',
           payload_install: 'update',
           platform: 'update',
           state_topic: ->(entity) { "#{entity.device.publish_topic_prefix}/firmware" }
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
      $LOGGER.debug "Update info #{name}"
      json_message = JSON.parse(message).deep_symbolize_keys unless message.is_a?(Hash)
      @ip_address = json_message[:wifi_sta][:ip]
      @device_id = json_message[:mac]
      @output.state = json_message[:relays][0][:ison]
      @input.state = json_message[:inputs][0][:input]
      $LOGGER.debug("Setting current version to #{json_message[:update][:old_version]}")
      @sw_version.latest_version = json_message[:update][:new_version] if json_message[:update][:new_version].present?
      @sw_version.state = json_message[:update][:old_version]
      $LOGGER.debug("Setting latest version to #{@sw_version.latest_version}")
    end

    def sw_version_adapter(message)
      json_message = JSON.parse(message).deep_symbolize_keys unless message.is_a?(Hash)
      @sw_version.in_progress = %w[updating].include?(json_message[:update][:status])
      @sw_version.update_percentage = @sw_version.in_progress ? 0.0 : nil
      json_message[:update][:old_version]
    end

    def call_to_update(message)
      return unless message == 'update'

      $LOGGER.info "Updating #{name} to latest"
      mqtt_client.publish("shellies/#{unique_id}/command", 'update_fw')
      @sw_version.in_progress = true
      @sw_version.update_percentage = 0.0
    end

    def mqtt_client
      Config.singleton.relay_mqtt
    end

    def post_state_update(entity_name)
      client.update_relay_state(@output.state&.downcase) if entity_name.to_s == 'Output'
    end

    def state_update_callback(message)
      message
    end

    def client
      @client ||= Mqtt::Clients::Shelly1.new(mqtt_client, "shellies/#{unique_id}")
    end

    def float_adapter(value)
      value.to_f
    end

    def integer_adapter(value)
      value.to_i
    end
  end
end
