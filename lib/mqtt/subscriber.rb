module Mqtt
  class Subscriber
    def subscribe!
      tputs "Starting subscription..."
      ht = handler_topic_listeners
      hc = handler_command_listeners
      tputs "Subscribing to updates on relay mqtt topic #{Config.singleton.aggregated_topics.keys}"
      Config.singleton.relay_mqtt.subscribe(Config.singleton.aggregated_topics.keys) if Config.singleton.aggregated_topics.keys.present?
      tputs "Subscribing to updates on home assistant mqtt topic #{Config.singleton.aggregated_command_topics.keys}"
      Config.singleton.home_assistant_mqtt.subscribe(Config.singleton.aggregated_command_topics.keys) if Config.singleton.aggregated_command_topics.keys.present?
      ht.join && hc.join
    end

    def handler_topic_listeners
      Thread.new do
        Config.singleton.relay_mqtt.get do |topic, message|
          tputs "Got message from topic #{topic} -> #{message}"
          if Config.singleton.aggregated_topics[topic].present?
            handle(topic, Config.singleton.aggregated_topics[topic], message)
          else
            tpus "Unknown handler for #{topic}"
          end
        end
      rescue => e
        puts "#{e.message}"
        puts "#{e.backtrace.join("\n")}"
        exit(1)
      end
    end

    def handler_command_listeners
      Thread.new do
        Config.singleton.home_assistant_mqtt.get do |topic, message|
          tputs "Got command from topic #{topic} -> #{message}"
          if Config.singleton.aggregated_command_topics[topic].present?
            handle(topic, Config.singleton.aggregated_command_topics[topic], message)
          else
            tpus "Unknown command handler for #{topic}"
          end
        end
      rescue => e
        tputs "Exception in relay listener: #{e.message}"
        tputs "#{e.backtrace.join("\n")}"
        exit(1)
      end
    end

    def handle(topic, handlers, message)
      puts "MMM: handlers == #{handlers}" if topic == 'blighvid/shelly-living-far-downlights/command'
      Thread.new do
        handlers.each do |handler|
          state_to_update = handler[:state]
          adapted_info = message
          if handler[:entity_adapter_method].present?
            adapted_info = handler[:entity].send("#{handler[:entity_adapter_method]}", message)
          elsif handler[:device_adapter_method].present?
            adapted_info = handler[:device].send("#{handler[:device_adapter_method]}", message)
          end
          if handler[:entity]
            tputs "Setting #{handler[:entity].name}'s #{state_to_update} to #{adapted_info}"
            handler[:entity].send("#{state_to_update}=", adapted_info) if handler[:entity]
          end
        end
      rescue => e
        tputs "Exception in handler for topic #{topic}: #{e.message}"
        tputs "The handler info -> #{handlers}"
        tputs "#{e.backtrace.join("\n")}"
        exit(1)
      end
    end
  end
end
