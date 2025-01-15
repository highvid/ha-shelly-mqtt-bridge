module Mqtt
  class TopicHandlerFactory
    attr_reader :handlers

    def handle(topic:, message:)
      handler = @handlers.find { |handle| self.class.handle?(handle.topic, topic) }
      return unless handler.present?

      handler.process(topic:, message:) if self.class.handle?(handler.topic, topic)
    end

    private

    def initialize
      @handlers = []
    end

    class << self
      attr_reader :singleton

      def register(handler_class:, topics:, publisher_client:)
        @singleton ||= new
        topics.each do |topic|
          unique_id = object_id_from_topic(topic)
          @singleton.handlers << handler_class.new(unique_id:, publisher_client:, topic:)
        end
      end

      def handle?(handler_topic, topic)
        splits = handler_topic.split('/')
        splits = splits[0..-2] if splits[-1] == '#'
        topic.split('/')[0..(splits.length - 1)] == splits
      end
    end
  end
end
