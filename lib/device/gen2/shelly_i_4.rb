module Device
  module Gen2
    class ShellyI4
      DEVICE = 'ShellyI4'.freeze
      MANUFACTURER = Config::BLIGHVID
      STATE_KEY = :switch

      include Publishable
      prepend Components::Gen2::IterativeSensor
      prepend Components::Gen2::Versionable
      include Base

      define_sensors :input, 4, sensor_klass: :binary_sensor

      listener_topics 'status', update_method: :post_status_update
    end
  end
end
