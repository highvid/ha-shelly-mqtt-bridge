module Components
  module Gen1
    module SingleSwitchOutput
      # rubocop:disable Metrics/AbcSize
      def self.prepended(base)
        base.class_eval do
          switch  :output,
                  callback: :state_update_callback,
                  command_topic: ->(entity) { "#{entity.device.publish_topic_prefix}/command" },
                  configuration_url: ->(entity) { "http://#{entity.device.ip_address}" },
                  entity_constructor: lambda { |device|
                    { unique_id: "#{device.unique_id}-relay", initial_value: 'OFF' }
                  },
                  hw_version: "#{Config::BLIGHVID.capitalize}-#{base::DEVICE}",
                  identifiers: ->(entity) { [entity.device.unique_id] },
                  json_attributes_topic: ->(entity) { "#{Config::BLIGHVID}/#{entity.unique_id}/attributes" },
                  listener_topics: 'relay/0',
                  manufacturer: base::MANUFACTURER,
                  model: base::DEVICE,
                  name: ->(_entity) { 'Output' },
                  state_topic: ->(entity) { "#{entity.device.publish_topic_prefix}/output" }
        end
      end
      # rubocop:enable Metrics/AbcSize

      def update_info(message)
        super
        update_output_info(message)
      end

      def update_output_info(message)
        json_message = JSON.parse(message).deep_symbolize_keys unless message.is_a?(Hash)
        @output.state = json_message[:relays][0][:ison]
      end

      def state_update_callback(message)
        message
      end

      def post_state_update(entity_name)
        control_client.update_relay_state(@output.state&.downcase) if entity_name.to_s == 'Output'
      end
    end
  end
end
