module Device
  module Gen1
    class ShellyEm
      DEVICE       = 'ShellyEM'.freeze
      MANUFACTURER = "#{Config::BLIGHVID}Em".freeze

      include Publishable
      prepend Components::Gen1::SingleSwitchOutput
      prepend Components::Gen1::Versionable

      attr_reader :raw_reactive_power0, :raw_reactive_power1

      sensor  :energy0, :energy1,
              configuration_url: ->(entity) { "http://#{entity.device.ip_address}" },
              device_class: 'energy',
              entity_constructor: lambda { |device, entity_name|
                { unique_id: "#{device.unique_id}-energy-#{entity_name[-1]}", initial_value: 0.0 }
              },
              hw_version: "#{Config::BLIGHVID.capitalize}-#{DEVICE}",
              identifiers: ->(entity) { [entity.device.unique_id] },
              json_attributes_topic: ->(entity) { "#{Config::BLIGHVID}/#{entity.unique_id}/attributes" },
              listener_topics: ->(entity) { "emeter/#{entity.name[-1]}/total" },
              manufacturer: MANUFACTURER,
              model: DEVICE,
              name: ->(entity) { "Energy Consumed #{entity.unique_id[-1]}" },
              number_type: :to_w_h,
              state_class: 'total_increasing',
              state_topic: ->(entity) { "#{Config::BLIGHVID}/#{entity.device.unique_id}/energy/#{entity.name[-1]}" },
              suggested_display_precision: 2,
              unit_of_measurement: 'Wh'
      sensor  :energy_returned0, :energy_returned1,
              configuration_url: ->(entity) { "http://#{entity.device.ip_address}" },
              device_class: 'energy',
              entity_constructor: lambda { |device, entity_name|
                { unique_id: "#{device.unique_id}-energy-returned-#{entity_name[-1]}", initial_value: 0.0 }
              },
              hw_version: "#{Config::BLIGHVID.capitalize}-#{DEVICE}",
              identifiers: ->(entity) { [entity.device.unique_id] },
              json_attributes_topic: ->(entity) { "#{Config::BLIGHVID}/#{entity.unique_id}/attributes" },
              listener_topics: ->(entity) { "emeter/#{entity.name[-1]}/total_returned" },
              manufacturer: MANUFACTURER,
              model: DEVICE,
              name: ->(entity) { "Energy Returned #{entity.unique_id[-1]}" },
              number_type: :to_w_h,
              state_class: 'total_increasing',
              state_topic: lambda { |entity|
                "#{Config::BLIGHVID}/#{entity.device.unique_id}/energy_returned/#{entity.name[-1]}"
              },
              suggested_display_precision: 2,
              unit_of_measurement: 'Wh'
      sensor  :power0, :power1,
              configuration_url: ->(entity) { "http://#{entity.device.ip_address}" },
              device_class: 'power',
              entity_constructor: lambda { |device, entity_name|
                { unique_id: "#{device.unique_id}-power-#{entity_name[-1]}", initial_value: 0.0 }
              },
              hw_version: "#{Config::BLIGHVID.capitalize}-#{DEVICE}",
              identifiers: ->(entity) { [entity.device.unique_id] },
              json_attributes_topic: ->(entity) { "#{Config::BLIGHVID}/#{entity.unique_id}/attributes" },
              listener_topics: ->(entity) { "emeter/#{entity.name[-1]}/power" },
              manufacturer: MANUFACTURER,
              model: DEVICE,
              name: ->(entity) { "Power #{entity.unique_id[-1]}" },
              number_type: :to_f,
              state_topic: ->(entity) { "#{Config::BLIGHVID}/#{entity.device.unique_id}/power/#{entity.name[-1]}" },
              suggested_display_precision: 2,
              unit_of_measurement: 'W'
      sensor  :voltage0, :voltage1,
              configuration_url: ->(entity) { "http://#{entity.device.ip_address}" },
              device_class: 'voltage',
              entity_constructor: lambda { |device, entity_name|
                { unique_id: "#{device.unique_id}-voltage-#{entity_name[-1]}", initial_value: 0.0 }
              },
              hw_version: "#{Config::BLIGHVID.capitalize}-#{DEVICE}",
              identifiers: ->(entity) { [entity.device.unique_id] },
              json_attributes_topic: ->(entity) { "#{Config::BLIGHVID}/#{entity.unique_id}/attributes" },
              listener_topics: ->(entity) { "emeter/#{entity.name[-1]}/voltage" },
              manufacturer: MANUFACTURER,
              model: DEVICE,
              name: ->(entity) { "Voltage #{entity.unique_id[-1]}" },
              number_type: :to_f,
              state_topic: ->(entity) { "#{Config::BLIGHVID}/#{entity.device.unique_id}/voltage/#{entity.name[-1]}" },
              suggested_display_precision: 2,
              unit_of_measurement: 'V'
      sensor  :power_factor0, :power_factor1,
              configuration_url: ->(entity) { "http://#{entity.device.ip_address}" },
              device_class: 'power_factor',
              entity_constructor: lambda { |device, entity_name|
                { unique_id: "#{device.unique_id}-pf-#{entity_name[-1]}", initial_value: 0.0 }
              },
              hw_version: "#{Config::BLIGHVID.capitalize}-#{DEVICE}",
              identifiers: ->(entity) { [entity.device.unique_id] },
              json_attributes_topic: ->(entity) { "#{Config::BLIGHVID}/#{entity.unique_id}/attributes" },
              listener_topics: ->(entity) { "emeter/#{entity.name[-1]}/pf" },
              manufacturer: MANUFACTURER,
              model: DEVICE,
              name: ->(entity) { "Power Factor #{entity.unique_id[-1]}" },
              number_type: :to_f,
              state_topic: ->(entity) { "#{Config::BLIGHVID}/#{entity.device.unique_id}/pf/#{entity.name[-1]}" },
              suggested_display_precision: 2
      sensor  :reactive_power0, :reactive_power1,
              configuration_url: ->(entity) { "http://#{entity.device.ip_address}" },
              device_class: 'power_factor',
              entity_constructor: lambda { |device, entity_name|
                { unique_id: "#{device.unique_id}-reactive-#{entity_name[-1]}", initial_value: 0.0 }
              },
              hw_version: "#{Config::BLIGHVID.capitalize}-#{DEVICE}",
              identifiers: ->(entity) { [entity.device.unique_id] },
              json_attributes_topic: ->(entity) { "#{Config::BLIGHVID}/#{entity.unique_id}/attributes" },
              listener_topics: [{
                state: ->(entity) { "emeter/#{entity.name[-1]}/pf" },
                state_adapter_method: :reactive_adapter_method_on_pf_change
              }, {
                state: ->(entity) { "emeter/#{entity.name[-1]}/reactive_power" },
                state_adapter_method: :reactive_adapter_method_on_reactive_change
              }],
              manufacturer: MANUFACTURER,
              model: DEVICE,
              name: ->(entity) { "Reactive Power #{entity.unique_id[-1]}" },
              number_type: :to_f,
              state_topic: ->(entity) { "#{Config::BLIGHVID}/#{entity.device.unique_id}/reactive/#{entity.name[-1]}" },
              suggested_display_precision: 2,
              unit_of_measurement: 'var'
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
        @raw_reactive_power0 = 0.0
        @raw_reactive_power1 = 0.0
        init!(options)
      end

      def announce_message_process(message)
        json_message = JSON.parse(message).deep_symbolize_keys unless message.is_a?(Hash)
        @ip_address = json_message[:wifi_sta][:ip]
        @device_id = json_message[:mac]
      end

      # rubocop:disable Metrics/AbcSize
      def update_info(message)
        AppLogger.debug "Update info #{name}"
        json_message = JSON.parse(message).deep_symbolize_keys unless message.is_a?(Hash)
        @ip_address = json_message[:wifi_sta][:ip]
        @device_id = json_message[:mac]
        @power0.state = json_message[:emeters][0][:power]
        @power1.state = json_message[:emeters][1][:power]
        @power_factor0.state = json_message[:emeters][0][:pf]
        @power_factor1.state = json_message[:emeters][1][:pf]
        @energy0.state = json_message[:emeters][0][:total]
        @energy1.state = json_message[:emeters][1][:total]
        @energy_returned0.state = json_message[:emeters][0][:total_returned]
        @energy_returned1.state = json_message[:emeters][1][:total_returned]
        @voltage0.state = json_message[:emeters][0][:voltage]
        @voltage1.state = json_message[:emeters][1][:voltage]
      end
      # rubocop:enable Metrics/AbcSize

      def reactive_adapter_method_on_pf_change(message, entity)
        index = entity.name[-1]
        raw_reactive_power = instance_variable_get("@raw_reactive_power#{index}")
        power_factor = message.to_f
        (raw_reactive_power * power_factor).round(2)
      end

      def reactive_adapter_method_on_reactive_change(message, entity)
        index = entity.name[-1]
        raw_reactive_power = instance_variable_set("@raw_reactive_power#{index}", message.to_f)
        power_factor = instance_variable_get("@power_factor#{index}")
        (raw_reactive_power * power_factor.state).round(2)
      end
    end
  end
end
