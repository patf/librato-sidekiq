module Librato
  module Sidekiq
    class ClientMiddleware < Middleware
      def self.reconfigure
        # puts "Reconfiguring with: #{options}"
        ::Sidekiq.configure_client do |config|
          config.client_middleware do |chain|
            chain.remove self
            chain.add self, options
          end
        end
      end

      protected

      def track(stats, worker_instance, msg, queue, elapsed, status_bucket)
        Librato.group 'sidekiq' do |sidekiq|
          sidekiq.increment 'queued'
          return unless allowed_to_submit queue, worker_instance
          sidekiq.group queue.to_s do |q|
            q.increment 'queued'

            next unless class_metrics_enabled

            # using something like User.delay.send_email invokes
            # a class name with slashes. remove them in favor of underscores
            q.group msg['class'].underscore.gsub('/', '_') do |w|
              w.increment 'queued'
            end
          end
        end
      end
    end
  end
end
