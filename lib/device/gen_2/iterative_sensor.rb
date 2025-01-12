module Device
  module Gen2
    module IterativeSensor
      extend ActiveSupport::Concern

      class_methods do
        attr_reader :sensor_array

        def define_sensors(sensor_type, count, sensor_klass: :sensor)
          @sensor_array ||= {}
          gen_klass = Device::Gen2.const_get("#{sensor_type.to_s.camelize}Sensor")
          if count == 1
            (@sensor_array[gen_klass] ||= []) << sensor_type
          else
            (0..(count - 1)).each { |index| (@sensor_array[gen_klass] ||= []) << "#{sensor_type}_#{index}" }
          end
          send(sensor_klass, *@sensor_array[gen_klass],
               **gen_klass::SENSOR_OPTIONS.call(self::DEVICE, self::MANUFACTURER))
          class_eval do
            prepend gen_klass
          end
        end
      end

      def post_status_update(message)
        super
        json_message = hashified_message(message)
        self.class.sensor_array.each do |klass, sensors|
          sensors.each_with_index do |sensor, index|
            instance_variable_get("@#{sensor}").state = json_message.dig(:"#{state_key(klass)}:#{index}", *klass::KEYS)
          end
        end
      end

      def state_key(klass)
        klass == Device::Gen2::InputSensor ? 'input' : 'switch'
      end
    end
  end
end
