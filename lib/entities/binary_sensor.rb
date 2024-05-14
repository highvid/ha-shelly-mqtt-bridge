module Entities
  class BinarySensor
    include AnemicEntity
  
    attribute :topic, listen_topic: true
    attribute :configuration_url, in_state: true, aggregate_key: :device
    attribute :device_class, in_state: true
    attribute :hw_version, in_state: true, aggregate_key: :device
    attribute :identifiers, in_state: true, aggregate_key: :device
    attribute :json_attributes
    attribute :json_attributes_topic, in_state: true, publish_topic: true, publish_method: :json_attributes, publish_periodicity: 60
    attribute :manufacturer, in_state: true, aggregate_key: :device
    attribute :model, in_state: true, aggregate_key: :device
    attribute :payload_off, in_state: true
    attribute :payload_on, in_state: true
    attribute :state, default: '0', track_update?: true, sanitize: :sanitize_value
    attribute :state_topic, in_state: true, publish_topic: true, publish_method: :state, publish_periodicity: 60
    attribute :unique_id, in_state: true
    attribute :unit_of_measurement, in_state: true
    attribute :value_template, in_state: true
  
    def initialize(unique_id:, initial_value: '0')
      self.component ||= 'binary_sensor'
      self.unique_id = unique_id
      self.state = initial_value
    end
    
    protected

    def is_postive?(value)
      if value.is_a?(String)
        if %w[0 1].include?(value)
          value == '1'
        elsif %w[true false].include?(value.downcase)
          value.downcase == 'true'
        elsif %w[on off].include?(value.downcase)
          value.downcase == 'on'
        else
          false
        end
      elsif [FalseClass, TrueClass].include?(value.class)
        value
      elsif value.is_a?(Integer)
        value != 0
      else
        false
      end
    end
  
    private
  
    def sanitize_value(value)
      is_postive?(value) ? 'ON' : 'OFF'
    end
  end
end
