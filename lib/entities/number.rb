module Entities
  class Number < Sensor
    def initialize(unique_id:, initial_value:)
      self.component ||= 'number'
      super
    end
  end
end
