require 'forwardable'

class AppLogger
  class << self
    extend Forwardable
    attr_reader :app_logger

    def_delegators :@app_logger, :debug, :info, :warn, :error

    def init!
      return if @app_logger.present?

      @app_logger = Logger.new($stdout, level: ENV.fetch('LOG_LEVEL', 'info').downcase.to_sym)
    end
  end
end
