module Device
  module Gen1
    class Shelly1
      DEVICE       = 'Shelly1'.freeze
      MANUFACTURER = Config::BLIGHVID

      include Publishable
      prepend Components::Gen1::SingleInput
      prepend Components::Gen1::SingleSwitchOutput
      prepend Components::Gen1::Versionable

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
        update_entities_states(json_message)
      end

      def update_entities_states(json_message)
        @ip_address = json_message[:wifi_sta][:ip]
        @device_id = json_message[:mac]
      end
    end
  end
end
