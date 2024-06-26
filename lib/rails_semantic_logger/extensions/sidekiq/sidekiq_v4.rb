# Sidekiq v4 patches
#
# To re-enable stdout logging for sidekiq server processes, add the following snippet to config/initializers/sidekiq.rb:
#   Sidekiq.configure_server do |config|
#     SemanticLogger.add_appender(io: $stdout, level: :debug, formatter: :color)
#   end
require "sidekiq/exception_handler"
require "sidekiq/logging"
require "sidekiq/middleware/server/logging"
require "sidekiq/processor"
require "sidekiq/worker"
module Sidekiq
  # Replace Sidekiq context with Semantic Logger
  module Logging
    def self.with_context(msg, &block)
      SemanticLogger.tagged(msg, &block)
    end
  end

  # Convert string to machine readable format
  class Processor
    def log_context(item)
      event       = { jid: item["jid"] }
      event[:bid] = item["bid"] if item["bid"]
      event
    end
  end

  # Let Semantic Logger handle duration logging
  module Middleware
    module Server
      class Logging
        def call(worker, item, queue)
          worker.logger.info("Start #perform")
          worker.logger.measure_info(
            "Completed #perform",
            on_exception_level: :error,
            log_exception: :full,
            metric: "Sidekiq/#{worker.class.name}/perform"
          ) do
            yield
          end
        end
      end
    end
  end

  # Logging within each worker should use its own logger
  module Worker
    attr_accessor :jid

    def self.included(base)
      raise ArgumentError, "You cannot include Sidekiq::Worker in an ActiveJob: #{base.name}" if base.ancestors.any? { |c| c.name == "ActiveJob::Base" }

      base.extend(ClassMethods)
      base.include(SemanticLogger::Loggable)
      base.class_attribute :sidekiq_options_hash
      base.class_attribute :sidekiq_retry_in_block
      base.class_attribute :sidekiq_retries_exhausted_block
    end
  end

  # Exception is already logged by Semantic Logger during the perform call
  module ExceptionHandler
    class Logger
      def call(ex, ctxHash)
        Sidekiq.logger.warn(ctxHash) if !ctxHash.empty?
      end
    end
  end
end

