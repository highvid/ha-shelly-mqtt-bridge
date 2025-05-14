module Components
  module Gen1
    module DoubleInput
      # rubocop:disable Metrics/AbcSize
      def self.prepended(base)
        base.class_eval do
          binary_sensor :input0, :input1,
                        configuration_url: ->(entity) { "http://#{entity.device.ip_address}" },
                        entity_constructor: lambda { |device, entity_name|
                          { unique_id: "#{device.unique_id}-input-#{entity_name[-1]}" }
                        },
                        hw_version: "#{Config::BLIGHVID.capitalize}-#{base::DEVICE}",
                        identifiers: ->(entity) { [entity.device.unique_id] },
                        json_attributes_topic: ->(entity) { "#{Config::BLIGHVID}/#{entity.unique_id}/attributes" },
                        listener_topics: ->(entity) { "input/#{entity.name[-1]}" },
                        manufacturer: base::MANUFACTURER,
                        model: base::DEVICE,
                        name: ->(entity) { "Input #{entity.unique_id[-1]}" },
                        state_topic: lambda { |entity|
                          "#{Config::BLIGHVID}/#{entity.device.unique_id}/input/#{entity.name[-1]}"
                        }
        end
      end
      # rubocop:enable Metrics/AbcSize

      def update_info(message)
        super
        update_input_info(message)
      end

      def update_input_info(message)
        json_message = JSON.parse(message).deep_symbolize_keys unless message.is_a?(Hash)
        @input0.state = json_message[:inputs][0][:input]
        @input1.state = json_message[:inputs][1][:input]
      end
    end
  end
end
