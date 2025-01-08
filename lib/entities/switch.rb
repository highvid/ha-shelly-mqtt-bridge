module Entities
  class Switch < BinarySensor
    attribute :command_topic, in_state: true, command_topic: true, command_update_field: :state,
                              command_callback: :callback
    attribute :callback
    def initialize(unique_id:, initial_value:)
      self.component ||= 'switch'
      super
    end
  end
end
