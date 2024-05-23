module Device
  module Publishable
    extend ActiveSupport::Concern

    def initialized
      @initialized = false if @initialized.nil?
      @initialized
    end

    def entities
      raise 'Device not initialized' unless initialized
      @entities
    end

    attr_reader :announce_topic, :announce_listen_topic, :announce_output, :announce_payload, :device_id, :ip_address,
                :name, :post_init_update_announce, :topic, :topic_base, :topic_hash, :unique_id

    def publish_topic_prefix
      "blighvid/#{unique_id}"
    end

    def generate_topic(string)
      "#{topic_base}/#{string}"
    end

    class_methods do
      attr_accessor :entities, :topic_hash
      def method_missing(method_name, *names, **arguments, &block)
        class_name = method_name.to_s.singularize.camelize
        if Entities.constants.include?(class_name.to_sym)
          tputs "Defining #{class_name}"
          names.each { |name| setup_entity(name, arguments.merge(class: Entities.const_get(class_name)), block) }
        elsif class_name == 'ListenerTopic'
          self.topic_hash ||= {}
          self.topic_hash.merge!(names.uniq.to_h do |topic_name|
            [ topic_name, { state: nil, device_adapter_method: arguments[:update_method] } ]
          end)
        else
          super
        end
      end

      def setup_entity(entity_name, arguments, block)
        (self.entities ||= []) << { entity_name:, block:,**arguments }
      end
    end

    def assign!(options = {})
      options.each do |key, value|
        instance_variable_set("@#{key}", value);
      end
      splits = topic.split('/')
      @topic_base = splits[-1] == '#' ? splits[0..-2].join('/') : splits[0..-1].join('/')
    end

    def init!(options = {})
      return if initialized

      announce!
      @entities = self.class.entities.map { |entity| initialize_entity(entity.dup) }
      @entities.each { |entity| entity.initialize!(self) }
      send(@post_init_update_announce, @announce_output) if post_init_update_announce.present?
      @initialized = true
    end

    def announce!
      client = Config.singleton.relay_mqtt
      announcement = Thread.new do
        _topic, message = Timeout.timeout(5) { client.get }
        Thread.current[:output]  = message
      rescue Timeout::Error
        tputs "Retrying publishing for announcement on #{@announce_topic} "
        client.publish(@announce_topic, @announce_payload)
        retry
      end
      tputs "Subscribing for announcement on #{@announce_listen_topic} "
      client.subscribe(@announce_listen_topic)
      tputs "Publishing for announcement on #{@announce_topic} "
      trigger_announce
      announcement.join
      tputs "Announcement received #{@announce_listen_topic}"
      client.unsubscribe(@announce_listen_topic)
      @announce_output = announcement[:output]
      tputs "Announcement output for #{self.unique_id} #{@announce_output}"
      send(@announce_method_adapter, @announce_output)
    end

    def trigger_announce(client: Config.singleton.relay_mqtt)
      client.publish(@announce_topic, @announce_payload)
    end

    def force_publish_all!
      entities.each { |entity| entity.force_publish_all! }
    end

    def initialize_entity(entity_hash)
      entity_name = entity_hash.delete(:entity_name)
      constructor = entity_hash.delete(:entity_constructor)
      raise "Unknown constructor lambda provided for #{entity_name}" unless constructor.is_a?(Proc)

      klass = entity_hash.delete(:class)
      options = constructor.parameters.length == 2 ? constructor.call(self, entity_name) : constructor.call(self)
      entity = klass.new(**options)
      name = options.delete(:name)
      entity.name = name.present? ? (name.is_a?(Proc) ? name.call(entity) : name ) : entity_name
      entity.device = self
      block = entity_hash.delete(:block)

      entity.add_entity_listener_topic(entity_hash.delete(:listener_topics))
      entity_hash.each do |key, value|
        derived_value = value.is_a?(Proc) ? value.call(entity) : value
        entity.send("#{key}=", derived_value)
      end
      entity.json_attributes = { ip: @ip_address, device_id: @device_id, model: DEVICE, manufacturuer: Config::BLIGHVID }

      block.call(entity) if block.present?
      self.instance_variable_set("@#{entity_name}", entity)
    end

    def all_relay_topic_listeners
      return @all_relay_topic_listeners if @all_relay_topic_listeners.present?
      @all_relay_topic_listeners = SelfHealingHash.new
      @all_relay_topic_listeners.safe_merge!(self.class.topic_hash.to_h { |k, v| [generate_topic(k), v.merge(device: self)] })
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
