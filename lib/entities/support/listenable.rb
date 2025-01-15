module Entities
  module Support
    module Listenable
      def initialize!(_device)
        super
        setup_entity_listeners!
        setup_command_listeners!
      end

      def add_entity_listener_topic(info)
        (@entity_listener_topic ||= []) << info
      end

      def setup_entity_listeners!
        @topic_hash = SelfHealingHash.new
        @entity_listener_topic.each { |info| @topic_hash.safe_merge!(get_topics_from_attributes(info)) }
      end

      def setup_command_listeners!
        @command_topic_hash = {}
        self.class.command_listen_attributes.each do |attribute_name, info|
          topic = send(attribute_name)
          callback = send(info[:device_adapter_method]) if respond_to?(info[:device_adapter_method])
          @command_topic_hash[topic] = info.merge(entity: self, device: device, device_adapter_method: callback)
        end
      end
    end
  end
end
