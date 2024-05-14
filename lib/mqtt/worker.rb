module Mqtt
  class Worker
    attr_reader :client, :factory
    def initialize(client:, factory:)
      @client = client
      @factory = factory
    end
    def work
      Thread.new do
        client.get do |topic, message|
          factory.process(topic, mesage)
        end
      end
    end

    def 
  end
end
