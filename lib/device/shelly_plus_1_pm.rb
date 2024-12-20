module Device
  class ShellyPlus1Pm
    DEVICE = 'ShellyPlus1PM'
    include Publishable
    binary_sensor :input,
      configuration_url: -> (entity) { "http://#{entity.device.ip_address}" },
      entity_constructor: -> (device, _entity_name) { { unique_id: "#{device.unique_id}-input" } },
      hw_version: "#{Config::BLIGHVID.capitalize}-#{DEVICE}",
      identifiers: -> (entity) { [entity.device.unique_id] },
      json_attributes_topic: -> (entity) { "#{Config::BLIGHVID}/#{entity.unique_id}/attributes" },
      listener_topics: [state: "status/input:0", state_adapter_method: :input_adapter_method],
      manufacturer: "#{Config::BLIGHVID}",
      model: DEVICE,
      name: 'Input',
      state_topic: -> (entity) { "#{Config::BLIGHVID}/#{entity.device.unique_id}/input" }
    sensor :energy,
      configuration_url: -> (entity) { "http://#{entity.device.ip_address}" },
      device_class: 'energy',
      entity_constructor: -> (device) { { unique_id: "#{device.unique_id}-energy", initial_value: 0.0 } },
      hw_version: "#{Config::BLIGHVID.capitalize}-#{DEVICE}",
      identifiers: -> (entity) { [entity.device.unique_id] },
      json_attributes_topic: -> (entity) { "#{Config::BLIGHVID}/#{entity.unique_id}/attributes" },
      listener_topics: [state: "status/switch:0", state_adapter_method: :energy_adapter_method],
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
      entity_constructor: -> (device) { { unique_id: "#{device.unique_id}-power", initial_value: 0.0 } },
      hw_version: "#{Config::BLIGHVID.capitalize}-#{DEVICE}",
      identifiers: -> (entity) { [entity.device.unique_id] },
      json_attributes_topic: -> (entity) { "#{Config::BLIGHVID}/#{entity.unique_id}/attributes" },
      listener_topics: [state: "status/switch:0", state_adapter_method: :power_adapter_method],
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
      listener_topics: [state: "status/switch:0", state_adapter_method: :temperature_adapter_method],
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
      listener_topics: [state: "status/switch:0", state_adapter_method: :voltage_adapter_method],
      manufacturer: "#{Config::BLIGHVID}",
      model: DEVICE,
      name: 'Voltage',
      number_type: :to_f,
      state_topic: -> (entity) { "#{Config::BLIGHVID}/#{entity.device.unique_id}/voltage" },
      suggested_display_precision: 2,
      unit_of_measurement: 'V'
    sensor :current,
      configuration_url: -> (entity) { "http://#{entity.device.ip_address}" },
      device_class: 'current',
      entity_constructor: -> (device) { { unique_id: "#{device.unique_id}-current", initial_value: 0.0 } },
      hw_version: "#{Config::BLIGHVID.capitalize}-#{DEVICE}",
      identifiers: -> (entity) { [entity.device.unique_id] },
      json_attributes_topic: -> (entity) { "#{Config::BLIGHVID}/#{entity.unique_id}/attributes" },
      listener_topics: [state: "status/switch:0", state_adapter_method: :current_adapter_method],
      manufacturer: "#{Config::BLIGHVID}",
      model: DEVICE,
      name: 'Current',
      number_type: :to_f,
      state_topic: -> (entity) { "#{Config::BLIGHVID}/#{entity.device.unique_id}/current" },
      suggested_display_precision: 2,
      unit_of_measurement: 'A'
    switch :output,
      callback: :state_update_callback,
      command_topic: -> (entity) { "#{entity.device.publish_topic_prefix}/command" },
      configuration_url: -> (entity) { "http://#{entity.device.ip_address}" },
      entity_constructor: ->(device) { { unique_id: "#{device.unique_id}-light", initial_value: 'OFF' } },
      hw_version: "#{Config::BLIGHVID.capitalize}-#{DEVICE}",
      identifiers: -> (entity) { [entity.device.unique_id] },
      json_attributes_topic: -> (entity) { "#{Config::BLIGHVID}/#{entity.unique_id}/attributes" },
      listener_topics: [state: "status/switch:0", state_adapter_method: :output_adapter_method],
      manufacturer: "#{Config::BLIGHVID}",
      model: DEVICE,
      name: 'Output',
      state_topic: -> (entity) { "#{entity.device.publish_topic_prefix}/output" }
    update :sw_version,
      callback: :call_to_update,
      command_topic: -> (entity) { "#{entity.device.publish_topic_prefix}/update" },
      device_class: 'firmware',
      configuration_url: -> (entity) { "http://#{entity.device.ip_address}" },
      entity_constructor: ->(device) { { unique_id: "#{device.unique_id}-sw-version", initial_value: nil  } },
      hw_version: "#{Config::BLIGHVID.capitalize}-#{DEVICE}",
      identifiers: -> (entity) { [entity.device.unique_id] },
      json_attributes_topic: -> (entity) { "#{Config::BLIGHVID}/#{entity.unique_id}/attributes" },
      listener_topics: [ { state: 'events/rpc', state_adapter_method: :sw_version_adapter } ],
      manufacturer: "#{Config::BLIGHVID}",
      model: DEVICE,
      name: 'Firmware',
      payload_install: 'update',
      platform: 'update',
      state_topic: -> (entity) { "#{entity.device.publish_topic_prefix}/firmware" }

    
    listener_topics 'status', update_method: :post_status_update
    
    def initialize(**options)
      assign!(options)
      @announce_topics = {
        generate_topic('command') => [{
          listen_topic: generate_topic('announce'),
          payload: 'announce',
          process: :receive_announce,
          post_process: nil
        }, {
          listen_topic: generate_topic('status'),
          payload: 'status_update',
          process: :receive_status_message,
          post_process: :post_status_update
        }]
      }
      init!(options)
    end

    def receive_announce(message)
      $LOGGER.info "Receive announce for #{name}"
      json_message = JSON.parse(message).deep_symbolize_keys unless message.is_a?(Hash)
      @current_version = json_message[:ver]
    end

    def receive_status_message(message)
      json_message = JSON.parse(message).deep_symbolize_keys unless message.is_a?(Hash)
      @ip_address = json_message[:wifi][:sta_ip]
      @device_id = json_message[:sys][:mac]
    end

    def post_status_update(message)
      $LOGGER.info "Update info #{name}"
      json_message = JSON.parse(message).deep_symbolize_keys unless message.is_a?(Hash)
      @ip_address = json_message[:wifi][:sta_ip]
      @device_id = json_message[:sys][:mac]
      @output.state = json_message[:'switch:0'][:output]
      @input.state = json_message[:'input:0'][:state]
      @power.state = json_message[:'switch:0'][:apower]
      @energy.state = json_message[:'switch:0'][:aenergy][:total]
      @voltage.state = json_message[:'switch:0'][:voltage]
      @current.state = json_message[:'switch:0'][:current]
      @temperature.state = json_message[:'switch:0'][:temperature][:tC]
      $LOGGER.info("Setting current version to #{@current_version}")
      @sw_version.latest_version = json_message[:sys].try(:[], :available_updates).try(:[], :stable).try(:[], :version) || @current_version
      @sw_version.state = @current_version
      $LOGGER.info("Setting latest version to #{@sw_version.latest_version}")
    end

    def post_state_update(entity_name)
      http_client.update_output_state(@output.state&.downcase) if entity_name.to_s == 'Output'
    end

    def input_adapter_method(message)
      json_message = JSON.parse(message).deep_symbolize_keys unless message.is_a?(Hash)
      json_message[:state]
    end

    def output_adapter_method(message)
      json_message = JSON.parse(message).deep_symbolize_keys unless message.is_a?(Hash)
      json_message[:output]
    end

    def status_adapter_method(message)
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
      json_message[:voltage]
    end

    def sw_version_adapter(message)
      json_message = JSON.parse(message).deep_symbolize_keys unless message.is_a?(Hash)
      if json_message[:method] == 'NotifyEvent'
        params = json_message[:params]
        if params[:events].present? && params[:events].any? { |event| %w[ota_begin ota_progress ota_success].include?(event[:event]) }
          events = params[:events]
          events.each do |event|
            @sw_version.in_progress = %w[ota_begin ota_progress].include?(event[:event])
            @sw_version.update_percentage = @sw_version.in_progress ? (event[:progress_percent] || 0.0) : nil
            @current_version = @sw_version.in_progress ? @current_version : @sw_version.latest_version
          end
        end
      end
      @current_version
    end

    def call_to_update(message)
      if message == 'update'
        $LOGGER.info "Updating #{name} to latest"
        mqtt_client.publish("shellies/#{unique_id}/command/sys", 'ota_update_to_stable')
        @sw_version.in_progress = true
        @sw_version.update_percentage = 0.0
      end
      @current_version
    end

    def state_update_callback(message)
      message
    end

    def http_client
      @http_client ||= HttpClient::ShellyPlus1Pm.new(ip_address)
    end

    def mqtt_client
      Config.singleton.relay_mqtt
    end

    def float_adapter(value)
      value.to_f
    end

    def integer_adapter(value)
      value.to_i
    end
  end
end
