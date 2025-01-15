module Publishables
  module Entitiable
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
        names.each { |name| setup_entity(name, arguments.merge(klass: Entities.const_get(class_name)), block) }
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
      self.entities = superclass.entities.dup if entities_inheritance?
      (self.entities ||= []) << { entity_name:, block:, **arguments }
    end

    def entities_inheritance?
      entities.blank? && superclass.respond_to?(:entities) && superclass.entities.is_a?(Array)
    end
  end
end
