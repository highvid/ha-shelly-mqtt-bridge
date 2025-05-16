module Device
  module Gen2
    class ShellyPlus1Pm
      DEVICE = 'ShellyPlus1PM'.freeze
      MANUFACTURER = Config::BLIGHVID
      STATE_KEY = :switch

      include Publishable
      prepend Components::Gen2::IterativeSensor
      prepend Components::Gen2::Versionable
      include Base

      define_sensors :input, 1, sensor_klass: :binary_sensor
      define_sensors :energy, 1
      define_sensors :power, 1
      define_sensors :temperature, 1
      define_sensors :voltage, 1
      define_sensors :current, 1
      define_sensors :output, 1, sensor_klass: :switch

      listener_topics 'status', update_method: :post_status_update
    end
  end
end
