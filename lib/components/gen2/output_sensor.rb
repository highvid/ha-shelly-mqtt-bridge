module Components
  module Gen2
    module OutputSensor
      KEYS = %i[output].freeze
      SENSOR_OPTIONS = lambda { |device_name, manufacturer_name, index, state_key|
        {
          callback: :state_update_callback,
          command_topic: ->(entity) { "#{entity.device.publish_topic_prefix}/command/#{index}" },
          configuration_url: ->(entity) { "http://#{entity.device.ip_address}" },
          entity_constructor: ->(device) { { unique_id: "#{device.unique_id}-output-#{index}", initial_value: 0.0 } },
          hw_version: "#{Config::BLIGHVID.capitalize}-#{device_name}",
          identifiers: ->(entity) { [entity.device.unique_id] },
          json_attributes_topic: lambda { |entity|
            "#{Config::BLIGHVID}/#{entity.device.unique_id}/output/attributes/#{index}"
          },
          listener_topics: [state: "status/#{state_key}:#{index}", state_adapter_method: :output_adapter_method],
          manufacturer: manufacturer_name,
          model: device_name,
          name: 'Output',
          state_topic: ->(entity) { "#{Config::BLIGHVID}/#{entity.device.unique_id}/output/#{index}" }
        }
      }

      def output_adapter_method(message)
        json_message = hashified_message(message)
        json_message.dig(*OutputSensor::KEYS)
      end

      def state_update_callback(message) = message

      def post_state_update(entity_name)
        puts "Post State Update for entity: #{entity_name}"
        return unless entity_name.to_s.downcase.start_with?('output')

        puts "Searching for entity: #{entity_name.parameterize(separator: '')}"
        state = instance_variable_get("@#{entity_name.parameterize(separator: '')}").state&.downcase
        publish_client.update_relay_state(state)
      end
    end
  end
end
