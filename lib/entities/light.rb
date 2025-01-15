module Entities
  class Light < Sensor
    attribute :brightness, track_update?: true
    attribute :brightness_callback
    attribute :brightness_command_topic, in_state: true, command_topic: true, command_update_field: :brightness,
                                         command_callback: :brightness_callback
    attribute :brightness_topic, in_state: true, publish_topic: true, publish_method: :brightness,
                                 publish_periodicity: 60
    attribute :brightness_scale, in_state: true
    attribute :command_topic, in_state: true, command_topic: true, command_update_field: :state,
                              command_callback: :callback
    attribute :callback

    def initialize(unique_id:, initial_value:)
      self.component ||= 'light'
      self.brightness_scale = 100
      super
    end

    private

    def sanitize_value(value)
      positive?(value) ? 'ON' : 'OFF'
    end
  end
end
