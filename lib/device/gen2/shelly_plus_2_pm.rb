module Device
  module Gen2
    class ShellyPlus2Pm
      DEVICE       = 'ShellyPlus2PM'.freeze
      MANUFACTURER = Config::BLIGHVID
      STATE_KEY    = :switch

      include Publishable
      prepend Components::Gen2::IterativeSensor
      prepend Components::Gen2::Versionable
      include Base

      define_sensors :input, 2, sensor_klass: :binary_sensor
      define_sensors :energy, 2
      define_sensors :power, 2
      define_sensors :temperature, 2
      define_sensors :voltage, 2
      define_sensors :current, 2
      define_sensors :output, 2, sensor_klass: :switch

      listener_topics 'status', update_method: :post_status_update
    end
  end
end
