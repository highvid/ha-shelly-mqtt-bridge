module Components
  module Gen1
    module Versionable
      # rubocop:disable Metrics/AbcSize
      def self.prepended(base)
        base.class_eval do
          update  :sw_version,
                  callback: :call_to_update,
                  command_topic: ->(entity) { "#{entity.device.publish_topic_prefix}/update" },
                  device_class: 'firmware',
                  configuration_url: ->(entity) { "http://#{entity.device.ip_address}" },
                  entity_constructor: lambda { |device|
                    { unique_id: "#{device.unique_id}-sw-version", initial_value: nil }
                  },
                  hw_version: "#{Config::BLIGHVID.capitalize}-#{base::DEVICE}",
                  identifiers: ->(entity) { [entity.device.unique_id] },
                  json_attributes_topic: ->(entity) { "#{Config::BLIGHVID}/#{entity.unique_id}/attributes" },
                  listener_topics: [{ state: 'info', state_adapter_method: :sw_version_adapter }],
                  manufacturer: base::MANUFACTURER,
                  model: base::DEVICE,
                  name: 'Firmware',
                  payload_install: 'update',
                  platform: 'update',
                  state_topic: ->(entity) { "#{entity.device.publish_topic_prefix}/firmware" }
        end
      end
      # rubocop:enable Metrics/AbcSize

      def update_info(message)
        super
        update_software_version_info(message)
      end

      def update_software_version_info(message)
        json_message = JSON.parse(message).deep_symbolize_keys unless message.is_a?(Hash)
        @sw_version.latest_version = json_message[:update][:new_version] if json_message[:update][:new_version].present?
        @sw_version.state = json_message[:update][:old_version]
      end

      def call_to_update(message)
        return unless message == 'update'

        AppLogger.info "Updating #{name} to latest"
        mqtt_client.publish("shellies/#{unique_id}/command", 'update_fw')
        @sw_version.in_progress = true
        @sw_version.update_percentage = 0.0
      end

      def sw_version_adapter(message)
        json_message = JSON.parse(message).deep_symbolize_keys unless message.is_a?(Hash)
        @sw_version.in_progress = %w[updating].include?(json_message[:update][:status])
        @sw_version.update_percentage = @sw_version.in_progress ? 0.0 : nil
        json_message[:update][:old_version]
      end
    end
  end
end
