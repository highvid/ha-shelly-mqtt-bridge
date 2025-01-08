module Device
  class ShellyPlus2Pm
    DEVICE = 'ShellyPlus2PM'.freeze
    include Publishable
    binary_sensor :input_0, :input_1,
                  configuration_url: ->(entity) { "http://#{entity.device.ip_address}" },
                  entity_constructor: lambda { |device, entity_name|
                    { unique_id: "#{device.unique_id}-input-#{entity_name[-1]}" }
                  },
                  hw_version: "#{Config::BLIGHVID.capitalize}-#{DEVICE}",
                  identifiers: ->(entity) { [entity.device.unique_id] },
                  json_attributes_topic: ->(entity) { "#{Config::BLIGHVID}/#{entity.unique_id}/attributes" },
                  listener_topics: [state: lambda { |entity|
                    "status/input:#{entity.name[-1]}"
                  }, state_adapter_method: :input_adapter_method],
                  manufacturer: Config::BLIGHVID.to_s,
                  model: DEVICE,
                  name: ->(entity) { "Input #{entity.unique_id[-1]}" },
                  state_topic: ->(entity) { "#{Config::BLIGHVID}/#{entity.device.unique_id}/input/#{entity.name[-1]}" }
    sensor :energy_0, :energy_1,
           configuration_url: ->(entity) { "http://#{entity.device.ip_address}" },
           device_class: 'energy',
           entity_constructor: lambda { |device, entity_name|
             { unique_id: "#{device.unique_id}-energy-#{entity_name[-1]}", initial_value: 0.0 }
           },
           hw_version: "#{Config::BLIGHVID.capitalize}-#{DEVICE}",
           identifiers: ->(entity) { [entity.device.unique_id] },
           json_attributes_topic: ->(entity) { "#{Config::BLIGHVID}/#{entity.unique_id}/attributes" },
           listener_topics: [state: lambda { |entity|
             "status/switch:#{entity.name[-1]}"
           }, state_adapter_method: :energy_adapter_method],
           manufacturer: Config::BLIGHVID.to_s,
           model: DEVICE,
           name: ->(entity) { "Energy #{entity.unique_id[-1]}" },
           number_type: :to_w_h,
           state_class: 'total_increasing',
           state_topic: ->(entity) { "#{Config::BLIGHVID}/#{entity.device.unique_id}/energy/#{entity.name[-1]}" },
           suggested_display_precision: 2,
           unit_of_measurement: 'Wh'
    sensor :power_0, :power_1,
           configuration_url: ->(entity) { "http://#{entity.device.ip_address}" },
           device_class: 'power',
           entity_constructor: lambda { |device, entity_name|
             { unique_id: "#{device.unique_id}-power-#{entity_name[-1]}", initial_value: 0.0 }
           },
           hw_version: "#{Config::BLIGHVID.capitalize}-#{DEVICE}",
           identifiers: ->(entity) { [entity.device.unique_id] },
           json_attributes_topic: ->(entity) { "#{Config::BLIGHVID}/#{entity.unique_id}/attributes" },
           listener_topics: [state: lambda { |entity|
             "status/switch:#{entity.name[-1]}"
           }, state_adapter_method: :power_adapter_method],
           manufacturer: Config::BLIGHVID.to_s,
           model: DEVICE,
           name: ->(entity) { "Power #{entity.unique_id[-1]}" },
           number_type: :to_f,
           state_topic: ->(entity) { "#{Config::BLIGHVID}/#{entity.device.unique_id}/power/#{entity.name[-1]}" },
           suggested_display_precision: 2,
           unit_of_measurement: 'W'
    sensor :temperature_0, :temperature_1,
           configuration_url: ->(entity) { "http://#{entity.device.ip_address}" },
           device_class: 'temperature',
           entity_constructor: lambda { |device, entity_name|
             { unique_id: "#{device.unique_id}-temperature-#{entity_name[-1]}", initial_value: 0.0 }
           },
           hw_version: "#{Config::BLIGHVID.capitalize}-#{DEVICE}",
           identifiers: ->(entity) { [entity.device.unique_id] },
           json_attributes_topic: ->(entity) { "#{Config::BLIGHVID}/#{entity.unique_id}/attributes" },
           listener_topics: [state: lambda { |entity|
             "status/switch:#{entity.name[-1]}"
           }, state_adapter_method: :temperature_adapter_method],
           manufacturer: Config::BLIGHVID.to_s,
           model: DEVICE,
           name: ->(entity) { "Temperature #{entity.unique_id[-1]}" },
           number_type: :to_f,
           state_topic: ->(entity) { "#{Config::BLIGHVID}/#{entity.device.unique_id}/temperature/#{entity.name[-1]}" },
           suggested_display_precision: 2,
           unit_of_measurement: '°C'
    sensor :voltage_0, :voltage_1,
           configuration_url: ->(entity) { "http://#{entity.device.ip_address}" },
           device_class: 'voltage',
           entity_constructor: lambda { |device, entity_name|
             { unique_id: "#{device.unique_id}-voltage-#{entity_name[-1]}", initial_value: 0.0 }
           },
           hw_version: "#{Config::BLIGHVID.capitalize}-#{DEVICE}",
           identifiers: ->(entity) { [entity.device.unique_id] },
           json_attributes_topic: ->(entity) { "#{Config::BLIGHVID}/#{entity.unique_id}/attributes" },
           listener_topics: [state: lambda { |entity|
             "status/switch:#{entity.name[-1]}"
           }, state_adapter_method: :voltage_adapter_method],
           manufacturer: Config::BLIGHVID.to_s,
           model: DEVICE,
           name: ->(entity) { "Voltage #{entity.unique_id[-1]}" },
           number_type: :to_f,
           state_topic: ->(entity) { "#{Config::BLIGHVID}/#{entity.device.unique_id}/voltage/#{entity.name[-1]}" },
           suggested_display_precision: 2,
           unit_of_measurement: 'V'
    sensor :current_0, :current_1,
           configuration_url: ->(entity) { "http://#{entity.device.ip_address}" },
           device_class: 'current',
           entity_constructor: lambda { |device, entity_name|
             { unique_id: "#{device.unique_id}-current-#{entity_name[-1]}", initial_value: 0.0 }
           },
           hw_version: "#{Config::BLIGHVID.capitalize}-#{DEVICE}",
           identifiers: ->(entity) { [entity.device.unique_id] },
           json_attributes_topic: ->(entity) { "#{Config::BLIGHVID}/#{entity.unique_id}/attributes" },
           listener_topics: [state: lambda { |entity|
             "status/switch:#{entity.name[-1]}"
           }, state_adapter_method: :current_adapter_method],
           manufacturer: Config::BLIGHVID.to_s,
           model: DEVICE,
           name: ->(entity) { "Current #{entity.unique_id[-1]}" },
           number_type: :to_f,
           state_topic: ->(entity) { "#{Config::BLIGHVID}/#{entity.device.unique_id}/current/#{entity.name[-1]}" },
           suggested_display_precision: 2,
           unit_of_measurement: 'A'
    switch :output_0, :output_1,
           callback: :state_update_callback,
           command_topic: ->(entity) { "#{entity.device.publish_topic_prefix}/command/#{entity.name[-1]}" },
           configuration_url: ->(entity) { "http://#{entity.device.ip_address}" },
           entity_constructor: lambda { |device, entity_name|
             { unique_id: "#{device.unique_id}-light-#{entity_name[-1]}", initial_value: 'OFF' }
           },
           hw_version: "#{Config::BLIGHVID.capitalize}-#{DEVICE}",
           identifiers: ->(entity) { [entity.device.unique_id] },
           json_attributes_topic: ->(entity) { "#{Config::BLIGHVID}/#{entity.unique_id}/attributes" },
           listener_topics: [state: lambda { |entity|
             "status/switch:#{entity.name[-1]}"
           }, state_adapter_method: :output_adapter_method],
           manufacturer: Config::BLIGHVID.to_s,
           model: DEVICE,
           name: ->(entity) { "Output #{entity.unique_id[-1]}" },
           state_topic: ->(entity) { "#{entity.device.publish_topic_prefix}/output/#{entity.name[-1]}" }
    update :sw_version,
           callback: :call_to_update,
           command_topic: ->(entity) { "#{entity.device.publish_topic_prefix}/update" },
           device_class: 'firmware',
           configuration_url: ->(entity) { "http://#{entity.device.ip_address}" },
           entity_constructor: ->(device) { { unique_id: "#{device.unique_id}-sw-version", initial_value: nil } },
           hw_version: "#{Config::BLIGHVID.capitalize}-#{DEVICE}",
           identifiers: ->(entity) { [entity.device.unique_id] },
           json_attributes_topic: ->(entity) { "#{Config::BLIGHVID}/#{entity.unique_id}/attributes" },
           listener_topics: [{ state: 'events/rpc', state_adapter_method: :sw_version_adapter }],
           manufacturer: Config::BLIGHVID.to_s,
           model: DEVICE,
           name: 'Firmware',
           payload_install: 'update',
           platform: 'update',
           state_topic: ->(entity) { "#{entity.device.publish_topic_prefix}/firmware" }
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
      json_message = JSON.parse(message).deep_symbolize_keys unless message.is_a?(Hash)
      @current_version = json_message[:ver]
    end

    def receive_status_message(message)
      json_message = JSON.parse(message).deep_symbolize_keys unless message.is_a?(Hash)
      @ip_address = json_message[:wifi][:sta_ip]
      @device_id = json_message[:sys][:mac]
    end

    def post_status_update(message)
      AppLogger.debug "Update info #{name}"
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
      AppLogger.debug("Setting current version to #{@current_version}")
      @sw_version.latest_version = json_message[:sys].try(:[], :available_updates).try(:[], :stable).try(:[],
                                                                                                         :version) || @current_version
      @sw_version.state = @current_version
      AppLogger.debug("Setting latest version to #{@sw_version.latest_version}")
    end

    def post_state_update(entity_name)
      output = instance_variable_get("@output_#{entity_name[-1]}")
      return unless ['output 0', 'output 1'].include?(entity_name.to_s.downcase)

      client.update_relay_state(output.state&.downcase, entity_name[-1])
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
      json_message[:voltage]
    end

    def state_update_callback(message)
      message
    end

    def sw_version_adapter(message)
      json_message = JSON.parse(message).deep_symbolize_keys unless message.is_a?(Hash)
      if json_message[:method] == 'NotifyEvent'
        params = json_message[:params]
        if params[:events].present? && params[:events].any? do |event|
          %w[ota_begin ota_progress ota_success].include?(event[:event])
        end
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
        AppLogger.info "Updating #{name} to latest"
        mqtt_client.publish("shellies/#{unique_id}/command/sys", 'ota_update_to_stable')
        @sw_version.in_progress = true
        @sw_version.update_percentage = 0.0
      end
      @current_version
    end

    def client
      @client ||= Mqtt::Clients::ShellyPlus2Pm.new(mqtt_client, "shellies/#{unique_id}")
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
