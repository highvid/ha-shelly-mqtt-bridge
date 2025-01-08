module Entities
  class Sensor < BinarySensor
    attribute :number_type
    attribute :state_class, in_state: true
    attribute :suggested_display_precision, in_state: true
    def initialize(unique_id:, initial_value:)
      self.component ||= 'sensor'
      super
    end

    def sanitize_value(value)
      if value.present? && number_type.present?
        value.send(number_type)
      else
        value
      end
    end
  end
end
