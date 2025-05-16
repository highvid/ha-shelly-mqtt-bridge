module Device
  module Gen2
    module Base
      def initialize(**options)
        assign!(options)
        @announce_topics = {
          generate_topic('command') => [{
            listen_topic: generate_topic('announce'),
            payload: 'announce',
            process: :receive_announce,
            post_process: nil
          }, {
            listen_topic: generate_topic('status'),
            payload: 'status_update',
            process: :receive_status_message,
            post_process: :post_status_update
          }]
        }
        init!(options)
      end

      def receive_announce(message); end

      def receive_status_message(message)
        json_message = hashified_message(message)
        @ip_address = json_message[:wifi][:sta_ip]
        @device_id = json_message[:sys][:mac]
      end

      def post_status_update(message)
        AppLogger.debug "Update info #{name}"
        json_message = hashified_message(message)
        @ip_address = json_message[:wifi][:sta_ip]
        @device_id = json_message[:sys][:mac]
      end

      def status_adapter_method(message); end
    end
  end
end
