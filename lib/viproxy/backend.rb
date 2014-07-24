module EventMachine
  module ProxyServer
    class Backend < EventMachine::Connection
      attr_accessor :plexer, :name, :debug

      def initialize(debug = false)
        @debug = debug
        @connected = EM::DefaultDeferrable.new
      end

      def connection_completed
        debug [@name, :conn_complete]
        @plexer.connected(@name)
        @connected.succeed

        #puts "START_TLS is initiating with the server using #{$sslcert} file"
        start_tls  if $ssl
      end

      def receive_data(data)
        puts "Received data from the backend..."
        debug [@name, data]
        @plexer.relay_from_backend(@name, data)
      end

      # Buffer data until the connection to the backend server
      # is established and is ready for use
      def send(data)
        @connected.callback { send_data data }
      end

      # Notify upstream plexer that the backend server is done
      # processing the request
      def unbind
        debug [@name, :unbind]
        @plexer.unbind_backend(@name)
      end

      private

      def debug(*data)
        return unless @debug
        require 'pp'
        pp data
        puts
      end
    end
  end
end
