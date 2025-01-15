module Entities
  module Support
    module Accessibillty
      def attributes
        @attributes ||= {}
      end

      def attributes=(value)
        @attributes = value
      end

      def [](name)
        send(name)
      end
    end
  end
end
