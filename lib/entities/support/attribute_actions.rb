module Entities
  module Support
    module AttributeActions
      module ClassMethods
        def inherited(child_class)
          super if defined?(super)
          %w[ aggregate_keys attribute_defaults command_listen_attributes in_state_attributes publish_attributes
              renamed_keys sanitized_attributes sensitive_attributes ].each do |key|
            child_class.instance_variable_set("@#{key}", send(key).dup)
          end
        end

        def attribute(*names, **options)
          names.each do |attribute_name|
            define_attribute_methods(attribute_name, sanitize_method: options[:sanitize])
            define_options(attribute_name, options)
          end
        end

        def define_options(attribute_name, options)
          set_options(attribute_name, options)
          options_for_listening(attribute_name,
                                *options.values_at(:command_topic, :command_update_field, :command_callback))
          set_boolean_options(attribute_name, options)
          option_for_publishing(attribute_name,
                                *options.values_at(:publish_topic, :publish_method, :publish_periodicity))
        end

        def define_attribute_methods(attribute_name, sanitize_method:)
          define_attribute_method(attribute_name)
          define_attribute_assignment(attribute_name, method_name: "#{attribute_name}=",
                                                      post_attribute_method: :post_attribute_publish, sanitize_method:)
          define_attribute_assignment(attribute_name, method_name: "#{attribute_name}_with_update=",
                                                      post_attribute_method: :post_attribute_update, sanitize_method:)
        end

        def set_options(attribute_name, options)
          set_option(aggregate_keys, attribute_name, :aggregate_key, options)
          set_option(attribute_defaults, attribute_name, :default, options)
          set_option(renamed_keys, attribute_name, :renamed_key, options)
          set_option(sanitized_attributes, attribute_name, :sanitize, options)
        end

        def set_option(option_set, attribute_name, key, options)
          option_set[attribute_name] = options[key]
        end

        def set_boolean_options(attribute_name, options)
          set_boolean_option(in_state_attributes, attribute_name, options[:in_state])
          set_boolean_option(sensitive_attributes, attribute_name, options[:track_update?])
        end

        def set_boolean_option(option_set, attribute_name, value)
          value.is_a?(TrueClass) ? option_set << attribute_name : option_set >> attribute_name
        end

        def define_attribute_method(attribute_name)
          send(Config.method_definition, attribute_name) { attributes[attribute_name] }
        end

        def define_attribute_assignment(attribute_name, method_name:, post_attribute_method:, sanitize_method:)
          send(Config.method_definition, method_name.to_sym) do |value|
            new_value = sanitized_value(attribute_name, value, sanitize_method)
            @has_changed = value_changed?(attribute_name, new_value)
            attributes[attribute_name] = new_value
            send(post_attribute_method, attribute_name) if @has_changed
            new_value
          end
        end

        def options_for_listening(name, command_topic, update_field, callback)
          return unless command_topic.present?

          command_listen_attributes[name] =
            { state: update_field, device_adapter_method: callback }
        end

        def option_for_publishing(name, topic, method, periodicity)
          return unless topic.present? && method.present? && periodicity.present?

          publish_attributes[name] = { method:, periodicity: }
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

      module InstanceMethods
        def sanitized_value(attribute, value, sanitize_method)
          return value unless self.class.sanitized_attributes.include?(attribute)

          send(sanitize_method, value)
        end

        def value_changed?(attribute_name, new_value)
          self.class.sensitive_attributes.include?(attribute_name) && attributes[attribute_name] != new_value &&
            device.present? && device.initialized
        end
      end
    end
  end
end
