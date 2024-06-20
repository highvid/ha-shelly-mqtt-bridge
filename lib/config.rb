require 'yaml'

class Config
  BLIGHVID = 'blighvid'
  attr_accessor :devices, :info
  attr_reader :device_info, :relay_mqtt, :home_assistant_mqtt

  def aggregated_topics
    return @aggregated_topics if @aggregated_topics.present?
    @aggregated_topics = SelfHealingHash.new
    devices.each { |device| @aggregated_topics.safe_merge!(device.all_relay_topic_listeners) }
    @aggregated_topics
  end

  def aggregated_command_topics
    return @aggregated_command_topics if @aggregated_command_topics.present?
    @aggregated_command_topics = SelfHealingHash.new
    devices.each { |device| @aggregated_command_topics.safe_merge!(device.all_command_topic_listeners) }
    @aggregated_command_topics
  end

  private

  def load_info(file_name: 'config/topics.yml.erb')
    if @info.blank?
      template = ERB.new File.new(file_name).read
      @info = YAML.load(template.result(binding)).deep_symbolize_keys
    end
  end

  def initialize
    load_info
    mqtt = @info[:mqtt]
    @relay_mqtt = MQTT::Client.connect(Config.mqtt_info(mqtt[:relay]))
    @home_assistant_mqtt = MQTT::Client.connect(Config.mqtt_info(mqtt[:home_assistant]))
    @device_info = @info[:devices] || []
  end

  class << self
    attr_reader :singleton

    def init!
      @singleton = new
      @singleton.devices = @singleton.device_info.map do |type, topics|
        klass = Device.const_get(type.to_s.camelize)
        topics.map do |topic|
          klass.new(
            name: Config.titleize(object_id_from_topic(topic)),
            topic:,
            unique_id: object_id_from_topic(topic),
          )
        end
      end.flatten
    end

    def mqtt_info(info)
      {
        client_id: SecureRandom.uuid,
        host: info[:host],
        port: info[:port],
        username: info[:username],
        password: info[:password]
      }
    end

    def object_id_from_topic(topic)
      components = topic.split('/')
      last = components[-1]
      last == '#' ? components[-2] : last
    end

    def method_definition
      @method_definition ||= if respond_to?(:define_method, true)
        :define_method
      else
        :define_singleton_method
      end
    end

    def titleize(string)
      string.to_s.titleize.tr('/', ' ')
    end

    def threadize(periodicity, initialize_periodicity)
      Thread.new do
        while true do
          result = yield
          sleep result ? periodicity :initialize_periodicity
        end
      rescue => e
        tputs "Exception: #{e.message}"
        tputs e.backtrace.join("\n")
        exit(1)
      end
    end
  end
end
