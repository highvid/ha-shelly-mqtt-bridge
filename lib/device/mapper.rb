module Device
  class Mapper
    attr_reader :topic, :message

    CLASS_MAPPER = {
      'SHDM-2' => Gen1::ShellyDimmer2,
      'SHEM' => Gen1::ShellyEm,
      'SHSW-1' => Gen1::Shelly1,
      'SHSW-25' => Gen1::Shelly25,
      'SHSW-PM' => Gen1::Shelly1Pm,
      'SNSN-0024X' => Gen2::ShellyI4,
      'SNSW-001P16EU' => Gen2::ShellyPlus1Pm,
      'SNSW-102P16EU' => Gen2::ShellyPlus2Pm,
      'S3DM-0A101WWL' => Gen3::ShellyDimmer,
      'S3SW-001P8EU' => Gen3::Shelly1PmMini,
      'S4SW-001P16EU' => Gen4::Shelly1Pm
    }.freeze

    def initialize(topic, message)
      @topic = topic
      @message = JSON.parse(message)
    end

    def const_get = CLASS_MAPPER[message['model']]

    def unique_id
      @unique_id ||= message['name'] || message['id']
    end

    def base_topic = "shellies/#{unique_id}/#"

    def device
      const_get.new(
        name: unique_id.to_s.titleize,
        topic: base_topic,
        unique_id: unique_id
      )
    end
  end
end
