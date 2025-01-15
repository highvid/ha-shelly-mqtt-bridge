module Entities
  module AnemicEntity
    HOME_ASSISTANT_PREFIX = 'homeassistant'.freeze
    extend ActiveSupport::Concern
    include Support::AttributeActions::InstanceMethods
    include Support::Accessibillty
    prepend Support::Publishable
    prepend Support::Listenable

    included do
      attr_accessor :component, :command_topic_hash, :discovery_topic, :device, :name, :topic_hash

      attribute :device_name, in_state: true, aggregate_key: :device, renamed_key: :name
      attribute :payload_topic, aggregate_key: :availability, renamed_key: :topic, in_state: true, publish_topic: true,
                                publish_periodicity: 60, publish_method: :online!
    end

    class_methods do
      include Support::AttributeActions::ClassMethods
    end

    def initialize
      self.class.attribute_defaults.each { |name, value| send(:"#{name}=", value) }
    end

    def changed?
      @has_changed = false if @has_changed.nil?
      previous_value = @has_changed

      @has_changed = false
      previous_value
    end

    def initialize!(device)
      associate_device!(device)
      setup_config_topic
    end

    def associate_device!(device)
      AppLogger.info "Initialising #{unique_id} for device #{device.name}"
      @device = device
      self.device_name = device.name
      self.payload_topic = "blighvid/#{unique_id}/availability"
    end

    def setup_config_topic
      @discovery_topic = "#{HOME_ASSISTANT_PREFIX}/#{component}/#{unique_id}/config"
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
        topic_hash.merge!(get_topics_from_array(info))
      end
      topic_hash
    end

    def get_topics_from_array(info)
      topic_hash = {}
      info.each do |topic_info|
        raise 'This should be a hash' unless topic_info.is_a?(Hash)

        adapter_method = adapter_method_from(topic_info)
        state = adapter_state_from(topic_info, adapter_method)
        topic = get_topic_from(topic_info[state.to_sym])
        device_adapter_method = topic_info[adapter_method]
        (topic_hash[topic] ||= []) << { state:, device_adapter_method:, entity: self, device: device }
      end
      topic_hash
    end

    def adapter_method_from(info)
      info.keys.filter { |k, _| k.to_s =~ /_adapter_method$/ }.first
    end

    def adapter_state_from(info, method)
      method.blank? ? info.first[0] : method[0..(method =~ /_adapter_method/) - 1]
    end

    def get_topic_from(topic)
      derived_topic = if topic.is_a?(String) || topic.is_a?(Symbol)
                        topic.to_s
                      elsif topic.is_a?(Proc)
                        topic.call(self).to_s
                      end
      device.generate_topic(derived_topic)
    end

    # def to_h
    #   duplicate_state = attributes.dup
    #   compiled_hash = {}
    #   self.class.aggregate_keys.each do |key, aggregate_key|
    #     renamed_key_name = self.class.renamed_keys.key?(key) ? self.class.renamed_keys[key] : key
    #     compiled_hash[aggregate_key] ||= {}
    #     value = duplicate_state[key]
    #     compiled_hash[aggregate_key][renamed_key_name] = duplicate_state.delete(key) if value.present?
    #   end
    #   self.class.publish_attributes.each do |attribute|
    #     value = duplicate_state[attribute]
    #     compiled_hash[attribute] = value if value.present?
    #   end
    #   compiled_hash[:name] = Config.titleize(unique_id)
    #   compiled_hash
    # end

    def post_attribute_update(attribute_name)
      entity_specific_attribute_update_method = "post_#{attribute_name}_update"
      if respond_to?(entity_specific_attribute_update_method)
        AppLogger.debug "Updating #{attribute_name}:#{entity_specific_attribute_update_method} on entity #{name}"
        send(entity_specific_attribute_update_method)
      end
      device_specific_attribute_update_method = entity_specific_attribute_update_method
      if device.respond_to?(device_specific_attribute_update_method)
        AppLogger.debug "Updating #{attribute_name}:#{entity_specific_attribute_update_method} on device for " \
                        "entity #{name}"
        device.send(device_specific_attribute_update_method, name)
      end
      post_attribute_publish(attribute_name)
    end
  end
end
