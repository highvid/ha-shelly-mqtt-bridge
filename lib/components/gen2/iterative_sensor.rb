module Components
  module Gen2
    module IterativeSensor
      extend ActiveSupport::Concern

      class_methods do
        attr_reader :sensor_array

        def define_sensors(type, count, sensor_klass: :sensor)
          @sensor_array ||= {}
          gen_klass = Components::Gen2.const_get("#{type.to_s.camelize}Sensor")
          @sensor_array[gen_klass] = count == 1 ? [type] : (0..(count - 1)).map { |index| "#{type}#{index}" }
          define_sensor_using(sensor_klass, gen_klass, *@sensor_array[gen_klass])
          prepend gen_klass
        end

        private

        def define_sensor_using(klass, gen_klass, *names)
          names.each_with_index do |name, index|
            send(klass, name, **generate_options(gen_klass::SENSOR_OPTIONS, index, only_one: names.length == 1))
          end
        end

        def generate_options(sensor_options, index, only_one: false)
          options = sensor_options.call(self::DEVICE, self::MANUFACTURER, index, self::STATE_KEY)
          options[:name] += " #{index}" unless only_one
          options
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
        klass == Components::Gen2::InputSensor ? 'input' : self.class::STATE_KEY
      end
    end
  end
end
