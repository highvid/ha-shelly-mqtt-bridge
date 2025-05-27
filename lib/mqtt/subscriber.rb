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
      subscribe_to_home_assistant_topics
      subscribe_to_announcements
      all_threads.each(&:join)
    rescue SignalException
      quit!
    end

    def subscribe_to_announcements
      relay_mqtt.subscribe('shellies/+/announce')
    end

    def subscribe_to_home_assistant_topics
      home_assistant_mqtt.subscribe(HOME_ASSISTANT_UPDATES_TOPIC)
    end

    def threads = []

    def all_threads
      @all_threads ||= threads
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
