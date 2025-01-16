module Device
  module Publishables
    module Topicable
      def all_relay_topic_listeners
        return @all_relay_topic_listeners if @all_relay_topic_listeners.present?

        @all_relay_topic_listeners = SelfHealingHash.new
        @all_relay_topic_listeners.safe_merge!(self.class.topic_hash.to_h do |k, v|
          [generate_topic(k), v.merge(device: self)]
        end)
        entities.each { |entity| @all_relay_topic_listeners.safe_merge!(entity.topic_hash) }
        @all_relay_topic_listeners
      end

      def all_command_topic_listeners
        return @all_command_topic_listeners if @all_command_topic_listeners.present?

        @all_command_topic_listeners = SelfHealingHash.new
        entities.each { |entity| @all_command_topic_listeners.safe_merge!(entity.command_topic_hash) }
        @all_command_topic_listeners
      end

      def publish_topic_prefix
        "blighvid/#{unique_id}"
      end

      def generate_topic(string)
        "#{topic_base}/#{string}"
      end
    end
  end
end
