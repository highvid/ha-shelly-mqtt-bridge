module Mqtt
  class Subscriber
    HOME_ASSISTANT_UPDATES_TOPIC = 'homeassistant/status'
    UPDATE_TOPIC = 'shellies/command'
    UPDATE_COMMANDS = %w[announce status_update]
    UPDATE_DELAY = 900

    def initialize
      @was_offline = false
      @now_online = true
    end

    def subscribe!
      tputs "Starting subscription...", level: 3
      tputs "Starting subscription..lev2.", level: 2
      ht = handler_topic_listeners
      hc = handler_command_listeners
      h_status_updates = handler_status_updates
      h_post_init_updates = handler_post_init_updates
      begin
        tputs "Subscribing to updates on relay mqtt topic #{Config.singleton.aggregated_topics.keys}"
        Config.singleton.relay_mqtt.subscribe(Config.singleton.aggregated_topics.keys) if Config.singleton.aggregated_topics.keys.present?
        tputs "Subscribing to updates on home assistant mqtt topic #{Config.singleton.aggregated_command_topics.keys}"
        Config.singleton.home_assistant_mqtt.subscribe(Config.singleton.aggregated_command_topics.keys) if Config.singleton.aggregated_command_topics.keys.present?
        tputs "Subscribing to updates from homeassitant"
        Config.singleton.home_assistant_mqtt.subscribe(HOME_ASSISTANT_UPDATES_TOPIC) if Config.singleton.aggregated_command_topics.keys.present?
        ht.join && hc.join && h_status_updates.join && h_post_init_updates.join
      rescue SignalException
        tputs "Attempting graceful shutdown"
        Config.singleton.quit!
        ht.kill && hc.kill
        Config.join
        Config.singleton.devices.each(&:publish_offline!)
      end
    end

    def handler_topic_listeners
      Thread.new do
        Config.singleton.relay_mqtt.get do |topic, message|
          tputs "Got message from topic #{topic} -> #{message}"
          if Config.singleton.aggregated_topics[topic].present?
            handle(topic, Config.singleton.aggregated_topics[topic], message)
          else
            tputs "Unknown handler for #{topic}", level: 2
          end
        end
      rescue => e
        puts "#{e.message}", level: 3
        puts "#{e.backtrace.join("\n")}", level: 3
        exit(1)
      end
    end

    def handler_command_listeners
      Thread.new do
        Config.singleton.home_assistant_mqtt.get do |topic, message|
          tputs "Got command from topic #{topic} -> #{message}"
          if Config.singleton.aggregated_command_topics[topic].present?
            handle(topic, Config.singleton.aggregated_command_topics[topic] || [], message, true)
          elsif topic == HOME_ASSISTANT_UPDATES_TOPIC
            @now_online = message == 'online'
            if @was_offline && @now_online
              tputs "Force updating all devices"
              Config.singleton.devices.each { |device| device.force_publish_all! }
            end
            @was_offline = message == 'offline'
          else
            tputs "Unknown command handler for #{topic}", level: 2
          end
        end
      rescue => e
        tputs "Exception in relay listener: #{e.message}", level: 3
        tputs "#{e.backtrace.join("\n")}", level: 3
        exit(1)
      end
    end

    def handle(topic, handlers, message, with_update = false)
      Thread.new do
        handlers.each do |handler|
          state_to_update = handler[:state]
          adapted_info = message
          if handler[:entity_adapter_method].present?
            adapted_info = handler[:entity].send("#{handler[:entity_adapter_method]}", message)
          elsif handler[:device_adapter_method].present?
            method = handler[:device].method(handler[:device_adapter_method])
            adapted_info = method.parameters.length == 1 ? handler[:device].send("#{handler[:device_adapter_method]}", message) : handler[:device].send("#{handler[:device_adapter_method]}", message, handler[:entity]) 
          end
          if handler[:entity]
            tputs "Setting #{handler[:entity].name}'s #{state_to_update}(w/#{with_update ? '' : 'o'} update) to #{adapted_info}"
            method_name = with_update ? "#{state_to_update}_with_update=" : "#{state_to_update}="
            handler[:entity].send(method_name, adapted_info)
          end
        end
      rescue => e
        tputs "Exception in handler for topic #{topic}: #{e.message}", level: 3
        tputs "The handler info -> #{handlers}", level: 3
        tputs "#{e.backtrace.join("\n")}", level: 3
        exit(1)
      end
    end

    def handler_status_updates
      Thread.new do
        while true
          sleep UPDATE_DELAY
          UPDATE_COMMANDS.each { |update_command|  Config.singleton.relay_mqtt.publish(UPDATE_TOPIC, update_command) }
        end
      end
    end

    def handler_post_init_updates
      Thread.new do
        puts "Starging checks"
        while Config.singleton.devices.any?(&:unitialized?)
          tputs "Waiting for devices to be initialized", level: 2
          sleep 10
        end
        tputs "All devices initialized", level: 2
      end
    end
  end
end
