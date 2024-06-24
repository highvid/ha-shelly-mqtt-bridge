module Entities
  module AnemicEntity
    HOME_ASSISTANT_PREFIX = "homeassistant"
    extend ActiveSupport::Concern
    included do
      attr_accessor :component, :command_topic_hash, :discovery_topic, :device, :name, :topic_hash
      attribute :device_name, in_state: true, aggregate_key: :device, renamed_key: :name
      attribute :payload_topic, aggregate_key: :availability, renamed_key: :topic, in_state: true, publish_topic: true, publish_periodicity: 60, publish_method: :online!
    end
  
    class_methods do
      def inherited(child_class)
        %w[aggregate_keys attribute_defaults command_listen_attributes
           in_state_attributes publish_attributes renamed_keys
           sanitized_attributes sensitive_attributes].each do |key|
          child_class.instance_variable_set("@#{key}", self.send(key).dup)
        end
      end
  
      def attribute(*names, **options)
        names.each do |attribute_name|
          send(Config.method_definition, attribute_name) { attributes[attribute_name] }
          send(Config.method_definition, :"#{attribute_name}=") do |value|
            new_value = self.class.sanitized_attributes.include?(attribute_name) ? send(options[:sanitize], value): value
            @has_changed = self.class.sensitive_attributes.include?(attribute_name) && attributes[attribute_name] != new_value && self.device.present? && self.device.initialized
            attributes[attribute_name] = new_value
            post_attribute_publish(attribute_name) if @has_changed
            new_value
          end
          send(Config.method_definition, :"#{attribute_name}_with_update=") do |value|
            new_value = self.class.sanitized_attributes.include?(attribute_name) ? send(options[:sanitize], value): value
            @has_changed = self.class.sensitive_attributes.include?(attribute_name) && attributes[attribute_name] != new_value && self.device.present? && self.device.initialized
            attributes[attribute_name] = new_value
            post_attribute_update(attribute_name) if @has_changed
            new_value
          end
          aggregate_keys[attribute_name] = options[:aggregate_key]
          attribute_defaults[attribute_name] = options[:default]
          options_for_listening(attribute_name, options[:command_topic], options[:command_update_field], options[:command_callback])
          options[:in_state].is_a?(TrueClass) ? in_state_attributes << attribute_name : in_state_attributes >> attribute_name
          option_for_publishing(attribute_name, options[:publish_topic], options[:publish_method], options[:publish_periodicity])
          renamed_keys[attribute_name] = options[:renamed_key]
          sanitized_attributes[attribute_name] = options[:sanitize]
          options[:track_update?].is_a?(TrueClass) ? sensitive_attributes << attribute_name : sensitive_attributes >> attribute_name
        end
      end

      def options_for_listening(name, command_topic, update_field, callback)
        if command_topic.present? && command_topic
          command_listen_attributes[name] = { state: update_field, device_adapter_method: callback }
        else
          command_listen_attributes[name] = nil
        end
      end

      def option_for_publishing(name, topic, method, periodicity)
        if topic.present? && method.present? && periodicity.present? && topic
          publish_attributes[name] = { method:, periodicity: }
        else
          publish_attributes[name] = nil
        end
      end
  
      def attribute_defaults
        @attribute_defaults ||= SelfHealingHash.new
      end
  
      def aggregate_keys
        @aggregate_keys ||= SelfHealingHash.new
      end

      def command_listen_attributes
        @command_listen_attributes ||= SelfHealingHash.new
      end
  
      def in_state_attributes
        @in_state_attributes ||= SelfHealingArray.new
      end

      def publish_attributes
        @publish_attributes ||= SelfHealingHash.new
      end

      def renamed_keys
        @renamed_keys ||= SelfHealingHash.new
      end
      
      def sensitive_attributes
        @sensitive_attributes ||= SelfHealingArray.new
      end
  
      def sanitized_attributes
        @sanitized_attributes ||= SelfHealingHash.new
      end
    end

    def publish_offline!
      tputs "Marking #{unique_id} as offline"
      Config.singleton.home_assistant_mqtt.publish(self.payload_topic, 'offline')
    end

    def online!
      tputs "Publishing online for #{unique_id}"
      'online'
    end

    def add_entity_listener_topic(info)
      (@entity_listener_topic ||= [] ) << info
    end
  
    def initialize
      self.class.attribute_defaults.each { |name, value| send(:"#{name}=", value) }
    end
  
    def attributes
      @attributes ||= {}
    end
  
    def attributes=(value)
      @attributes = value
    end
  
    def [](name)
      send(name)
    end

    def changed?
      @has_changed = false if @has_changed.nil?
      previous_value = @has_changed
  
      @has_changed = false
      previous_value
    end

    def initialize!(device)
      associate_device!(device)
      setup_entity_listeners!
      setup_command_listeners!
      setup_config_topic
      setup_publishers!
    end

    def associate_device!(device)
      @device = device
      self.device_name = device.name
      self.payload_topic = "blighvid/#{unique_id}/availability"
    end

    def setup_config_topic
      @discovery_topic = "#{HOME_ASSISTANT_PREFIX}/#{component}/#{unique_id}/config"
    end

    def setup_entity_listeners!
      @topic_hash = SelfHealingHash.new
      @entity_listener_topic.each { |info| @topic_hash.safe_merge!(get_topics_from_attributes(info)) }
    end

    #############################
    # types of supported format for entity listener topics
    # 1. listener_topics: 'abcd'
    # 2. listener_topics: ->(entity) { "#{entity.unique_id}/info" }
    # 3. listener_topics: [{ brightness: 'brightness' }]
    #############################

    def get_topics_from_attributes(info)
      topic_hash = {}
      if info.is_a?(String) || info.is_a?(Symbol) || info.is_a?(Proc)
        (topic_hash[get_topic_from(info)] ||= []) << { state: :state, entity: self }
      elsif info.is_a?(Array)
        info.each do |topic_info|
          adapter_method = topic_info.keys.filter { |k, _| k.to_s =~ /_adapter_method$/ }.first
          state = adapter_method.blank? ? topic_info.first[0] : adapter_method[0..(adapter_method =~ /_adapter_method/) -1]
          topic = get_topic_from(topic_info[state.to_sym])
          device_adapter_method = topic_info[adapter_method]
          (topic_hash[topic] ||= []) << { state:, device_adapter_method:, entity: self, device: self.device }
        end
      end
      topic_hash
    end

    def get_topic_from(topic)
      derived_topic = if topic.is_a?(String) || topic.is_a?(Symbol)
        topic.to_s
      elsif topic.is_a?(Proc)
        topic.call(self).to_s
      end
      device.generate_topic(derived_topic)
    end

    def setup_command_listeners!
      @command_topic_hash = {}
      self.class.command_listen_attributes.each do |attribute_name, info|
        topic = send(attribute_name)
        callback = send(info[:device_adapter_method]) if respond_to?(info[:device_adapter_method])
        @command_topic_hash[topic] = info.merge(entity: self, device: self.device, device_adapter_method: callback)
      end
    end

    def discovery_payload
      compiled_hash = SelfHealingHash.new
      self.class.in_state_attributes.each do |attribute_name|
        renamed_key_name = self.class.renamed_keys.key?(attribute_name) ? self.class.renamed_keys[attribute_name] : attribute_name
        value = send(attribute_name)
        if self.class.aggregate_keys.include?(attribute_name)
          compiled_hash[self.class.aggregate_keys[attribute_name]] ||= {}
          compiled_hash[self.class.aggregate_keys[attribute_name]][renamed_key_name] = value
        else
          compiled_hash[renamed_key_name] = value
        end
      end
      compiled_hash[:name] = self.name || Config.titleize(self.unique_id)
      compiled_hash
    end

    def to_h
      duplicate_state = self.attributes.dup
      compiled_hash = {}
      self.class.aggregate_keys.each do |key, aggregate_key|
        renamed_key_name = self.class.renamed_keys.key?(key) ? self.class.renamed_keys[key] : key
        compiled_hash[aggregate_key] ||= {}
        value = duplicate_state[key]
        compiled_hash[aggregate_key][renamed_key_name] = duplicate_state.delete(key) if value.present?
      end
      self.class.publish_attributes.each do |attribute|
        value = duplicate_state[attribute]
        compiled_hash[attribute] = value if value.present?
      end
      compiled_hash[:name] = Config.titleize(self.unique_id)
      compiled_hash
    end

    def config_published?
      @config_published ||= false
    end

    def force_publish_all!
      tputs "Force publishing on discovery topic #{@discovery_topic} for #{self.device.name}#"
      Config.singleton.home_assistant_mqtt.publish(@discovery_topic, discovery_payload.to_json)
      self.class.publish_attributes.each do |attribute_name, info|
        topic_name = send(attribute_name)
        value = send(info[:method])
        value = value.to_json if value.is_a?(Hash)
        tputs "Force publishing on #{topic_name} for #{self.device.name}##{self.name}##{info[:method]} = #{value}"
        Config.singleton.home_assistant_mqtt.publish(topic_name, value)
      end
    end

    def setup_publishers!
      Config.threadize(900, 5) do
        if self.device.initialized
          topic_name = @discovery_topic
          tputs "Periodic publishing on discovery topic #{topic_name} for #{self.device.name}#"
          Config.singleton.home_assistant_mqtt.publish(topic_name, discovery_payload.to_json)
          @config_published = true
        else
          false
        end
      end
      self.class.publish_attributes.each do |attribute_name, info|
        topic_name = send(attribute_name)
        tputs "Setting publisher for #{name} for attribute #{attribute_name} on topic #{topic_name}"
        Config.threadize(info[:periodicity], 10) do
          if self.device.initialized && self.config_published?
            value = send(info[:method])
            value = value.to_json if value.is_a?(Hash)
            tputs "Periodic publishing on #{topic_name} for #{self.device.name}##{self.name}##{info[:method]} = #{value}"
            Config.singleton.home_assistant_mqtt.publish(topic_name, value)
            true
          else
            false
          end
        end
      end
    end

    def post_attribute_update(attribute_name)
      entity_specific_attribute_update_method = "post_#{attribute_name}_update"
      if self.respond_to?(entity_specific_attribute_update_method)
        tputs "Updating state of #{attribute_name} using method #{entity_specific_attribute_update_method} on entity #{self.name}"
        send(entity_specific_attribute_update_method)
      end
      device_specific_attribute_update_method = entity_specific_attribute_update_method
      if self.device.respond_to?(device_specific_attribute_update_method)
        tputs "Updating state of #{attribute_name} using method #{entity_specific_attribute_update_method} on device for entity #{self.name}"
        device.send(device_specific_attribute_update_method, self.name)
      end
      post_attribute_publish(attribute_name)
    end

    def post_attribute_publish(attribute_name)
      state_topic = "#{attribute_name}_topic"
      if self.respond_to?(state_topic) && device.initialized && config_published?
        topic_name = send(state_topic)
        value = self.send(attribute_name)
        tputs "Publishging state(#{value}) update on #{topic_name}"
        Config.singleton.home_assistant_mqtt.publish(topic_name, value)
      end
    end
  end
end
