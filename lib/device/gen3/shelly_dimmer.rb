module Device
  module Gen3
    class ShellyDimmer
      DEVICE       = 'ShellyDimmerGen3'.freeze
      MANUFACTURER = Config::BLIGHVID
      STATE_KEY    = :light

      include Publishable
      prepend Components::Gen2::IterativeSensor
      prepend Components::Gen2::Versionable
      include Device::Gen2::Base

      define_sensors :input, 2, sensor_klass: :binary_sensor
      define_sensors :energy, 1
      define_sensors :power, 1
      define_sensors :temperature, 1
      define_sensors :voltage, 1
      define_sensors :current, 1
      define_sensors :light, 1, sensor_klass: :light

      listener_topics 'status', update_method: :post_status_update
    end
  end
end
