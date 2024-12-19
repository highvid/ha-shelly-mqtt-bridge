module Entities
  class Update < Switch
    attribute :installed_version, in_state: true
    attribute :latest_version, in_state: true
    attribute :payload_install, default: 'update', in_state: true
    attribute :in_progress, default: false, in_state: true
    attribute :update_percentage, default: nil, in_state: true
    def initialize(unique_id:, initial_value:)
      self.component ||= 'update'
      super
    end
  end
end
