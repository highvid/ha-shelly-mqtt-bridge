module Device
  module Publishables
    module Helper
      def options_from_contructor(constructor, entity_name)
        constructor.parameters.length == 2 ? constructor.call(self, entity_name) : constructor.call(self)
      end

      def safe_proc_execute(key, entity)
        key.is_a?(Proc) ? key.call(entity) : key
      end

      def mqtt_client
        Config.singleton.relay_mqtt
      end

      def force_publish_all!
        entities.each(&:force_publish_all!)
      end

      def publish_offline!
        entities.each(&:publish_offline!)
      end

      def float_adapter(value)
        value.to_f
      end

      def integer_adapter(value)
        value.to_i
      end

      def publish_client
        klass = self.class.to_s.gsub('Device::', '')
        @publish_client ||= Mqtt::Clients.const_get(klass).new(mqtt_client, "shellies/#{unique_id}")
      end

      def announcement_client
        @announcement_client ||= Config.singleton.create_announcement_client
      end

      def destroy_announcement_client!
        @announce_client.disconnect if @announce_client.present?
        @announce_client = nil
      end

      def initialized
        @initialized = false if @initialized.nil?
        @initialized
      end

      def unitialized?
        !initialized
      end

      def entities
        raise 'Device not initialized' if unitialized?

        @entities
      end

      def control_client
        klass = self.class.to_s.gsub('Device::', '')
        klass = Mqtt::Clients.const_get(klass)
        @control_client ||= klass.new(mqtt_client, "shellies/#{unique_id}")
      end
    end
  end
end
