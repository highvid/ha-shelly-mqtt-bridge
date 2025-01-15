module Device
  module Publishable
    extend ActiveSupport::Concern

    def self.included(base)
      base.extend(Publishables::Entitiable)
      base.include(Publishables::Topicable)
      base.include(Publishables::Helper)
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

    attr_reader :announce_topic, :announce_topics, :announce_listen_topic, :announce_output, :announce_payload,
                :device_id, :ip_address, :name, :post_announce_action, :topic, :topic_base, :topic_hash, :unique_id

    def assign!(options = {})
      options.each { |key, value| instance_variable_set("@#{key}", value) }
      splits = topic.split('/')
      @topic_base = splits[-1] == '#' ? splits[0..-2].join('/') : splits.join('/')
    end

    def init!(_options = {})
      return if initialized

      post_announce_actions = announce_multiple_topics!.compact.to_h
      @entities = self.class.entities
                      .map { |entity| initialize_entity(entity.dup) }
                      .each { |entity| entity.initialize!(self) }
      post_announce_actions.each { |action, message| send(action, message) }
      @initialized = true
    end

    def announce_multiple_topics!
      @announce_topics.map do |topic, metas|
        metas.map do |meta|
          output = announce_single_topic!(topic:, payload: meta[:payload],
                                          listen_topic: meta[:listen_topic],
                                          announce_method_process: meta[:process])
          [meta[:post_process], output] if meta[:post_process].present?
        end
      end.flatten(1)
    end

    def announce_single_topic!(topic:, payload:, listen_topic:, announce_method_process:)
      mqtt_client.subscribe(listen_topic)
      trigger_announce(topic:, payload:)
      thread = announcement_thread(topic, payload)
      thread.join
      mqtt_client.unsubscribe(listen_topic)
      announce_output = thread[:output]
      send(announce_method_process, announce_output)
      announce_output
    end

    def announcement_thread(topic, payload)
      @announcement_threads ||= {}
      topic_payload = "#{topic}-#{payload}"
      return @announcement_threads[topic_payload] if @announcement_threads[topic_payload].present?

      @announcement_threads[topic_payload] = Thread.new do
        _topic, message = Timeout.timeout(5) { mqtt_client.get }
        Thread.current[:output] = message
      rescue Timeout::Error
        AppLogger.warn "Retrying publishing for announcement on #{topic} and payload #{payload}"
        trigger_announce(topic:, payload:)
        retry if Config.singleton.infinite_loop
      end
    end

    def trigger_announce(topic:, payload:)
      mqtt_client.publish(topic, payload)
    end

    def initialize_entity(hash)
      meta = {}
      %i[entity_name entity_constructor klass listener_topics block name].each { |key| meta[key] = hash.delete(key) }
      raise "Unknown constructor lambda provided for #{meta[:entity_name]}" unless meta[:entity_constructor].is_a?(Proc)

      entity = initialize_entity_using(**meta.except(:block))
      initialize_entity_params(entity, hash)
      initialize_json_attributes(entity)
      initialize_block(entity, meta[:block])
      instance_variable_set("@#{meta[:entity_name]}", entity)
    end

    def initialize_entity_params(entity, hash)
      hash.each { |key, value| entity.send("#{key}=", safe_proc_execute(value, entity)) }
    end

    def initialize_block(entity, block)
      block&.call(entity)
    end

    def initialize_entity_using(entity_name:, entity_constructor:, klass:, listener_topics:, name:)
      options = options_from_contructor(entity_constructor, entity_name)
      entity = klass.new(**options)
      entity.name = name.present? ? safe_proc_execute(name, entity) : entity_name
      entity.device = self

      entity.add_entity_listener_topic(listener_topics)
      entity
    end

    def initialize_json_attributes(entity)
      entity.json_attributes = { ip: @ip_address, device_id: @device_id, model: self.class::DEVICE,
                                 manufacturer: entity.manufacturer, friendly_unique_id: entity.unique_id }
    end

    def hashified_message(message)
      message.is_a?(Hash) ? message.deep_symbolize_keys : JSON.parse(message).deep_symbolize_keys
    end
  end
end
