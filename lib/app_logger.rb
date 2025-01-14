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

    def exception(exception, context: 'ERR')
      @app_logger.error("#{context}\n#{e.message}\n#{exception.backtrace.join("\n")}")
    end
  end
end
