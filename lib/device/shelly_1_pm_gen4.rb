module Device
  class Shelly1PmGen4 < ShellyPlus1Pm
    DEVICE = 'Shelly1PMGen4'.freeze
    MANUFACTURER = Config::BLIGHVID

    include Publishable
    prepend Gen2::IterativeSensor
    prepend Gen2::Versionable
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
