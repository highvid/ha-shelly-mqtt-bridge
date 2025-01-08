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
  end
end
