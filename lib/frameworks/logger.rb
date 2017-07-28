require 'logging'

module FrameworksCapybara
  # configure logging
  module Logger
    def log_level
      log_levels = %w[warn info debug]
      env_log_level = (ENV['LOG_LEVEL'] || '').downcase
      log_levels.include?(env_log_level) ? env_log_level.to_sym : :debug
    end

    def log
      Logging.appenders.stdout(
        'stdout',
        layout: Logging.layouts.pattern(pattern: '[%d] %-7l %c: %m\n', color_scheme: default_style)
      )
      # rubocop:disable Style/GlobalVars
      # global log acceptable
      $log ||= new_log
      # rubocop:enable Style/GlobalVars
    end

    def default_style
      scheme = 'pldefault'
      Logging.color_scheme(
        scheme,
        levels: { info: :green, warn: :yellow, error: :red },
        date:    :cyan,
        logger:  :cyan,
        message: :cyan
      )
      scheme
    end

    def new_log
      log = Logging.logger['Color::Log']
      log.add_appenders 'stdout'
      log.level = :info
      log
    end
  end
end
