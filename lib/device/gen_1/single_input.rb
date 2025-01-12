module Device
  module Gen1
    module SingleInput
      def self.prepended(base)
        base.class_eval do
          binary_sensor :input,
                        configuration_url: ->(entity) { "http://#{entity.device.ip_address}" },
                        entity_constructor: ->(device, _entity_name) { { unique_id: "#{device.unique_id}-input" } },
                        hw_version: "#{Config::BLIGHVID.capitalize}-#{base::DEVICE}",
                        identifiers: ->(entity) { [entity.device.unique_id] },
                        json_attributes_topic: ->(entity) { "#{Config::BLIGHVID}/#{entity.unique_id}/attributes" },
                        listener_topics: 'input/0',
                        manufacturer: base::MANUFACTURER,
                        model: base::DEVICE,
                        name: 'Input',
                        state_topic: ->(entity) { "#{Config::BLIGHVID}/#{entity.device.unique_id}/input" }
        end
      end

      def update_info(message)
        super
        update_input_info(message)
      end

      def update_input_info(message)
        json_message = JSON.parse(message).deep_symbolize_keys unless message.is_a?(Hash)
        @input.state = json_message[:inputs][0][:input]
      end
    end
  end
end
