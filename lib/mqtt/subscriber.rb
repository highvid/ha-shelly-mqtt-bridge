module Mqtt
  class Subscriber
    HOME_ASSISTANT_UPDATES_TOPIC = 'homeassistant/status'.freeze

    prepend Support::Accessibility
    prepend Support::Listenable
    prepend Support::Publishable

    def initialize
      @was_offline = false
      @now_online = true
    end

    def subscribe!
      all_threads
      subscribe_to_aggregated_topics
      subscribe_to_aggregated_command_topics
      subscribe_to_home_assistant_topics
      all_threads.each(&:join)
    rescue SignalException
      quit!
    end

    def subscribe_to_aggregated_topics
      relay_mqtt.subscribe(aggregated_topics.keys) if aggregated_topics.keys.present?
    end

    def subscribe_to_aggregated_command_topics
      home_assistant_mqtt.subscribe(aggregated_command_topics.keys) if aggregated_command_topics.keys.present?
    end

    def subscribe_to_home_assistant_topics
      home_assistant_mqtt.subscribe(HOME_ASSISTANT_UPDATES_TOPIC)
    end

    def all_threads
      @all_threads ||= threads
    end

    def threads
      [handler_post_init_updates]
    end

    def handler_post_init_updates
      Thread.new do
        AppLogger.debug 'Starting checks'
        while Config.singleton.devices.any?(&:unitialized?)
          AppLogger.info 'Waiting for devices to be initialized'
          sleep 10
        end
        AppLogger.info 'All devices initialized'
      end
    end

    def quit!
      AppLogger.warn 'Attempting graceful shutdown'
      Config.singleton.quit!
      all_threads.each(&:kill)
      Config.join
      Config.singleton.devices.each(&:publish_offline!)
    end
  end
end
