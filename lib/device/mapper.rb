module Device
  class Mapper
    attr_reader :topic, :message

    CLASS_MAPPER = {
      'SHDM-2' => ShellyDimmer2,
      'SHEM' => ShellyEm,
      'SHSW-1' => Shelly1,
      'SHSW-25' => Shelly25,
      'SHSW-PM' => Shelly1Pm,
      'SNSW-001P16EU' => ShellyPlus1Pm,
      'SNSW-102P16EU' => ShellyPlus2Pm
    }.freeze

    def initialize(topic, message)
      @topic = topic
      @message = JSON.parse(message)
    end

    def const_get
      CLASS_MAPPER[message['model']]
    end

    def unique_id
      @unique_id ||= message['name'] || message['id']
    end

    def base_topic
      "shellies/#{unique_id}/#"
    end

    def device
      const_get.new(
        name: unique_id.to_s.titleize,
        topic: base_topic,
        unique_id: unique_id
      )
    end
  end
end
