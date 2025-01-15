module Device
  module Gen2
    module Versionable
      def self.prepended(base)
        base.class_eval do
          update  :sw_version,
                  callback: :call_to_update,
                  command_topic: ->(entity) { "#{entity.device.publish_topic_prefix}/update" },
                  device_class: 'firmware',
                  configuration_url: ->(entity) { "http://#{entity.device.ip_address}" },
                  entity_constructor: lambda { |device|
                    { unique_id: "#{device.unique_id}-firmware", initial_value: nil }
                  },
                  hw_version: "#{Config::BLIGHVID.capitalize}-#{base::DEVICE}",
                  identifiers: ->(entity) { [entity.device.unique_id] },
                  json_attributes_topic: lambda { |entity|
                    "#{Config::BLIGHVID}/#{entity.device.unique_id}/firmware/attributes"
                  },
                  listener_topics: [{ state: 'events/rpc', state_adapter_method: :sw_version_adapter }],
                  manufacturer: base::MANUFACTURER,
                  model: base::DEVICE,
                  name: 'Firmware',
                  payload_install: 'update',
                  platform: 'update',
                  state_topic: ->(entity) { "#{entity.device.publish_topic_prefix}/firmware" }
        end
      end

      def receive_announce(message)
        super
        json_message = JSON.parse(message).deep_symbolize_keys unless message.is_a?(Hash)
        @current_version = json_message[:ver]
      end

      def post_status_update(message)
        super
        update_software_version_info(message)
      end

      def update_software_version_info(message)
        json_message = hashified_message(message)
        @sw_version.latest_version = json_message[:sys]
                                     .try(:[], :available_updates).try(:[], :stable)
                                     .try(:[], :version) || @current_version
        @sw_version.state = @current_version
      end

      def call_to_update(message)
        if message == 'update'
          AppLogger.info "Updating #{name} to latest"
          mqtt_client.publish("shellies/#{unique_id}/command/sys", 'ota_update_to_stable')
          @sw_version.in_progress = true
          @sw_version.update_percentage = 0.0
        end
        @current_version
      end

      def sw_version_adapter(message)
        json_message = hashified_message(message)
        return @current_version unless json_message[:method] == 'NotifyEvent'

        params = json_message[:params]
        if update_events?(params[:events])
          params[:events].each do |event|
            @sw_version.in_progress = %w[ota_begin ota_progress].include?(event[:event])
            @sw_version.update_percentage = @sw_version.in_progress ? (event[:progress_percent] || 0.0) : nil
            @current_version = @sw_version.in_progress ? @current_version : @sw_version.latest_version
          end
        end
        @current_version
      end

      def update_events?(events)
        events&.any? { |event| %w[ota_begin ota_progress ota_success].include?(event[:event]) }
      end
    end
  end
end
