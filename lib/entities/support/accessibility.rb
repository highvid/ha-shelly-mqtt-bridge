module Entities
  module Support
    module Accessibility
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
