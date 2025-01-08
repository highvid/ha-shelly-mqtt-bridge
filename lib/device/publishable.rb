module Device
  module Publishable
    extend ActiveSupport::Concern

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

    def publish_topic_prefix
      "blighvid/#{unique_id}"
    end

    def generate_topic(string)
      "#{topic_base}/#{string}"
    end

    class_methods do
      attr_accessor :entities, :topic_hash

      def class_name_from_method(method_name)
        method_name.to_s.singularize.camelize
      end

      def respond_to_missing?(method_name, include_private = false)
        class_name = class_name_from_method(method_name)
        Entities.constants.include?(class_name.to_sym) || class_name == 'ListenerTopic' || super
      end

      def method_missing(method_name, *names, **arguments, &block)
        class_name = class_name_from_method(method_name)
        if Entities.constants.include?(class_name.to_sym)
          names.each { |name| setup_entity(name, arguments.merge(class: Entities.const_get(class_name)), block) }
        elsif class_name == 'ListenerTopic'
          self.topic_hash ||= {}
          self.topic_hash.merge!(names.uniq.to_h do |topic_name|
            [topic_name, { state: nil, device_adapter_method: arguments[:update_method] }]
          end)
        else
          super
        end
      end

      def setup_entity(entity_name, arguments, block)
        (self.entities ||= []) << { entity_name:, block:, **arguments }
      end
    end

    def assign!(options = {})
      options.each do |key, value|
        instance_variable_set("@#{key}", value)
      end
      splits = topic.split('/')
      @topic_base = splits[-1] == '#' ? splits[0..-2].join('/') : splits.join('/')
    end

    def init!(_options = {})
      return if initialized

      post_announce_actions = announce_multiple_topics!.compact.to_h
      @entities = self.class.entities.map { |entity| initialize_entity(entity.dup) }
      @entities.each { |entity| entity.initialize!(self) }
      post_announce_actions.each do |action, message|
        send(action, message)
      end
      @initialized = true
    end

    def announce_multiple_topics!
      @announce_topics.map do |topic, metas|
        metas.map do |meta|
          output = announce_single_topic!(topic, meta[:payload], meta[:listen_topic], meta[:process])
          [meta[:post_process], output] if meta[:post_process].present?
        end
      end.flatten(1)
    end

    def announce_single_topic!(topic_to_announce = @announce_topic, payload_to_announce = @announce_payload,
                               listen_topic = @announce_listen_topic, announce_method_process = @announce_method_adapter)
      client = Config.singleton.relay_mqtt
      announcement = Thread.new do
        _topic, message = Timeout.timeout(5) { client.get }
        Thread.current[:output] = message
      rescue Timeout::Error
        AppLogger.info "Retrying publishing for announcement on #{topic_to_announce}"
        client.publish(@announce_topic, @announce_payload)
        retry if Config.singleton.infinite_loop
      end
      AppLogger.debug "Subscribing for announcement on #{listen_topic} "
      client.subscribe(listen_topic)
      AppLogger.debug "Publishing for announcement on #{topic_to_announce} "
      trigger_announce(topic_to_announce:, payload_to_announce:)
      announcement.join
      AppLogger.debug "Announcement received #{listen_topic}"
      client.unsubscribe(listen_topic)
      announce_output = announcement[:output]
      AppLogger.debug "Announcement output for #{unique_id} #{announce_output}"
      send(announce_method_process, announce_output)
      announce_output
    end

    def trigger_announce(topic_to_announce:, payload_to_announce:, client: Config.singleton.relay_mqtt)
      client.publish(topic_to_announce, payload_to_announce)
    end

    def force_publish_all!
      entities.each(&:force_publish_all!)
    end

    def publish_offline!
      @entities.each(&:publish_offline!)
    end

    def initialize_entity(entity_hash)
      entity_name = entity_hash.delete(:entity_name)
      constructor = entity_hash.delete(:entity_constructor)
      raise "Unknown constructor lambda provided for #{entity_name}" unless constructor.is_a?(Proc)

      klass = entity_hash.delete(:class)
      options = constructor.parameters.length == 2 ? constructor.call(self, entity_name) : constructor.call(self)
      entity = klass.new(**options)
      name = options.delete(:name)
      entity.name = if name.present?
                      name.is_a?(Proc) ? name.call(entity) : name
                    else
                      entity_name
                    end
      entity.device = self
      block = entity_hash.delete(:block)

      entity.add_entity_listener_topic(entity_hash.delete(:listener_topics))
      entity_hash.each do |key, value|
        derived_value = value.is_a?(Proc) ? value.call(entity) : value
        entity.send("#{key}=", derived_value)
      end
      entity.json_attributes = { ip: @ip_address, device_id: @device_id, model: self.class::DEVICE,
                                 manufacturer: entity.manufacturer, friendly_unique_id: entity.unique_id }

      block.call(entity) if block.present?
      instance_variable_set("@#{entity_name}", entity)
    end

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
  end
end
