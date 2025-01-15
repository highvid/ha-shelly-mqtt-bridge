module Entities
  module Support
    module Publishable
      def initialize!(_device)
        super
        setup_publishers!
      end

      def publish_offline!
        home_assistant_publish(payload_topic, 'offline')
      end

      def online!
        'online'
      end

      def config_published?
        @config_published ||= false
      end

      def force_publish_all!
        home_assistant_publish(@discovery_topic, discovery_payload.to_json)
        self.class.publish_attributes.each do |attribute_name, info|
          topic_name = send(attribute_name)
          value = send(info[:method])
          value = value.to_json if value.is_a?(Hash)
          home_assistant_publish(topic_name, value)
        end
      end

      def setup_publishers!
        setup_initialize_thread!
        self.class.publish_attributes.each do |attribute_name, info|
          setup_attribute_publish(attribute_name, **info)
        end
      end

      def setup_initialize_thread!
        Config.threadize(900, 5) do
          if device.initialized
            topic_name = @discovery_topic
            home_assistant_publish(topic_name, discovery_payload.to_json)
            @config_published = true
          else
            false
          end
        end
      end

      def setup_attribute_publish(attribute_name, periodicity:, method:, **_)
        topic_name = send(attribute_name)
        Config.threadize(periodicity, 10) do
          if device.initialized && config_published?
            value = send(method)
            value = value.to_json if value.is_a?(Hash)
            home_assistant_publish(topic_name, value)
          else
            false
          end
        end
      end

      def post_attribute_publish(attribute_name)
        state_topic = "#{attribute_name}_topic"
        return unless respond_to?(state_topic) && device.initialized && config_published?

        topic_name = send(state_topic)
        value = send(attribute_name)
        AppLogger.debug "Publishging state(#{value}) update on #{topic_name}"
        home_assistant_mqtt.publish(topic_name, value)
      end

      def home_assistant_mqtt
        Config.singleton.home_assistant_mqtt
      end

      def home_assistant_publish(topic, message)
        home_assistant_mqtt.publish(topic, message) || true
      end

      def discovery_payload
        compiled_hash = SelfHealingHash.new
        self.class.in_state_attributes.each do |attribute_name|
          renamed_key_name = renamed_key(attribute_name)
          value = send(attribute_name)
          if aggregate_key?(attribute_name)
            aggregate_hash(compiled_hash, attribute_name, renamed_key_name, value)
          else
            compiled_hash[renamed_key_name] = value
          end
        end
        compiled_hash[:name] = name || Config.titleize(unique_id)
        compiled_hash
      end

      def renamed_key(attribute_name)
        self.class.renamed_keys[attribute_name] || attribute_name
      end

      def aggregate_key?(attribute_name)
        self.class.aggregate_keys.include?(attribute_name)
      end

      def aggregate_hash(hash, attribute_name, key, value)
        hash[self.class.aggregate_keys[attribute_name]] ||= {}
        hash[self.class.aggregate_keys[attribute_name]][key] = value
      end
    end
  end
end
