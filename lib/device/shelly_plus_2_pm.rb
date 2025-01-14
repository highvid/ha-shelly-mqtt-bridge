module Device
  class ShellyPlus2Pm
    DEVICE       = 'ShellyPlus2PM'.freeze
    MANUFACTURER = Config::BLIGHVID

    include Publishable
    prepend Gen2::IterativeSensor
    prepend Gen2::Versionable

    define_sensors :input, 2, sensor_klass: :binary_sensor
    define_sensors :energy, 2
    define_sensors :power, 2
    define_sensors :temperature, 2
    define_sensors :voltage, 2
    define_sensors :current, 2
    define_sensors :output, 2, sensor_klass: :switch

    listener_topics 'status', update_method: :post_status_update

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
      json_message = JSON.parse(message).deep_symbolize_keys unless message.is_a?(Hash)
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
