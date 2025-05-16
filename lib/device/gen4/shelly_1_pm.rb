module Device
  module Gen4
    class Shelly1Pm
      DEVICE = 'Shelly1PMGen4'.freeze
      MANUFACTURER = Config::BLIGHVID

      include Publishable
      prepend Components::Gen2::IterativeSensor
      prepend Components::Gen2::Versionable
      include Device::Gen2::Base

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
