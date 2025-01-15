require 'yaml'

class Config
  BLIGHVID = 'blighvid'.freeze
  attr_accessor :infinite_loop, :devices, :info
  attr_reader :aggregated_command_topics, :aggregated_topics, :device_info, :relay_mqtt, :home_assistant_mqtt

  def quit!
    @infinite_loop = false
  end

  def create_announcement_client
    MQTT::Client.connect(Config.mqtt_info(@info[:mqtt][:relay]))
  end

  def add_device(device)
    @devices << device
    @aggregated_command_topics.safe_merge!(device.all_command_topic_listeners)
    @aggregated_topics.safe_merge!(device.all_relay_topic_listeners)
  end

  private

  def load_info(file_name: 'config/topics.yml.erb')
    return unless @info.blank?

    template = ERB.new File.new(file_name).read
    @info = YAML.load(template.result(binding)).deep_symbolize_keys
  end

  def initialize
    @infinite_loop = true
    @devices = []
    load_info
    mqtt = @info[:mqtt]
    @relay_mqtt = MQTT::Client.connect(Config.mqtt_info(mqtt[:relay]))
    @home_assistant_mqtt = MQTT::Client.connect(Config.mqtt_info(mqtt[:home_assistant]))
    @aggregated_command_topics = SelfHealingHash.new
    @aggregated_topics = SelfHealingHash.new
  end

  class << self
    attr_reader :singleton, :threads

    def init!
      @singleton = new
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

    def threadize(periodicity, initialize_periodicity)
      @threads ||= []
      @threads << Thread.new do
        while Config.singleton.infinite_loop
          result = yield
          sleep result ? periodicity : initialize_periodicity
        end
      rescue StandardError => e
        AppLogger.exception(e)
        exit(1)
      end
    end

    def join
      return if @threads.blank?

      @threads.each(&:kill)
    end
  end
end
