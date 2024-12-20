module Entities
  class Update < Switch
    attribute :latest_version, track_update?: true
    attribute :payload_install, default: 'update', in_state: true
    attribute :platform, default: 'update', in_state: true
    attribute :in_progress, default: false, track_update?: true
    attribute :update_percentage, default: nil, track_update?: true
    def initialize(unique_id:, initial_value:)
      self.component ||= 'update'
      super
    end

    def sanitize_value(value)
      {
        installed_version: value,
        latest_version:,
        in_progress:,
        update_percentage:
      }.to_json
    end
  end
end
