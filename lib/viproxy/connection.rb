module EventMachine
  module ProxyServer
    class Connection < EventMachine::Connection
      attr_accessor :debug

      ##### Proxy Methods
      def on_data(&blk); @on_data = blk; end
      def on_response(&blk); @on_response = blk; end
      def on_finish(&blk); @on_finish = blk; end
      def on_connect(&blk); @on_connect = blk; end

      ##### EventMachine
      def initialize(options)
        @debug = options[:debug] || false
        @servers = {}
        set_replacefile($regexfile) if $regexfile
      end

      def post_init
        if $ssl
          start_tls :private_key_file => $sslcert, :cert_chain_file => $sslcert, :verify_peer => false
        end
      end

      def receive_data(data)
        debug [:connection, data]
        replace_it(data,"REQ") if $regexfile
        log("Client",data)
        processed = @on_data.call(data) if @on_data

        return if processed == :async or processed.nil?
        relay_to_servers(processed)
      end

      def relay_to_servers(processed)
        if processed.is_a? Array
          data, servers = *processed

          # guard for "unbound" servers
          servers = servers.collect {|s| @servers[s]}.compact
        else
          data = processed
          servers ||= @servers.values.compact
        end

        servers.each do |s|
          s.send_data data unless data.nil?
          puts "Client data sent to the server"
        end
      end

      #
      # initialize connections to backend servers
      #
      def server(name, opts)
        if opts[:socket]
          srv = EventMachine::connect_unix_domain(opts[:socket], EventMachine::ProxyServer::Backend, @debug) do |c|
            c.name = name
            c.plexer = self
            c.proxy_incoming_to(self, 10240) if opts[:relay_server]
          end
        else
          srv = EventMachine::bind_connect(opts[:bind_host], opts[:bind_port], opts[:host], opts[:port], EventMachine::ProxyServer::Backend, @debug) do |c|
            c.name = name
            c.plexer = self
            c.proxy_incoming_to(self, 10240) if opts[:relay_server]
          end
        end

        self.proxy_incoming_to(srv, 10240) if opts[:relay_client]

        @servers[name] = srv
      end

      #
      # [ip, port] of the connected client
      #
      def peer
        @peer ||= begin
          peername = get_peername
          peername ? Socket.unpack_sockaddr_in(peername).reverse : nil
        end
      end

      #
      # [ip, port] of the local server connect
      #
      def sock
        @sock ||= begin
          sockname = get_sockname
          sockname ? Socket.unpack_sockaddr_in(sockname).reverse : nil
        end
      end

      #
      # relay data from backend server to client
      #
      def relay_from_backend(name, data)
        puts "Backend sent data..."
        debug [:relay_from_backend, name, data]
        replace_it(data,"RES") if $regexfile
        log("Backend Server",data)
        data = @on_response.call(name, data) if @on_response
        send_data data unless data.nil?
      end

      def connected(name)
        debug [:connected]
        @on_connect.call(name) if @on_connect
      end

      def unbind
        debug [:unbind, :connection]

        # terminate any unfinished connections
        :relay.values.compact.each do |s|
          s.close_connection_after_writing
        end
      end

      def unbind_backend(name)
        debug [:unbind_backend, name]
        @servers[name] = nil
        close = :close

        if @on_finish
          close = @on_finish.call(name)
        end

        # if all connections are terminated downstream, then notify client
        if (@servers.values.compact.size.zero? && close != :keep) || (close == :close)
          close_connection_after_writing
        end
      end

      private

      def debug(*data)
        if @debug
          require 'pp'
          pp data
          puts
        end
      end

      def log(t,data)
        if $logfile
          logfile=File.new($logfile,'a')
          #logfile.puts "-------------#{t}--------------\n\n#{data}\n\n"
          logfile.puts "#{data}"
          logfile.close
        end
      end


      def replace_it(data,type)
        $replacement_table[type].each do |r,c|
          puts "Replacements are #{r} to #{c}"
          data.gsub!(r,c)
        end
        return data
      end

      def set_replacefile(f)
        puts "Replacement File is "+f.to_s
        $replacement_table = {}
        $replacement_table["RES"] = {}
        $replacement_table["REQ"] = {}
        contents=File.new(f, "r")
        contents.each do |line|
          next if line =~ /^#/ or line =~ /^\n/
          type=line.split("\t")[0]
          t = line.split("\t")[1]
          r = Regexp.new t
          c = line.split("\t")[2..1000].join("\t").chop

          if c =~ /FUZZ/
            str = "A" * c.split(" ")[1].to_i
            puts str
          else
            str = c
            puts str
          end

          case type
            when "RES"
              $replacement_table[type][r] = str
            when "REQ"
              $replacement_table[type][r] = str
            when "BOTH"
              $replacement_table["RES"][r] = str
              $replacement_table["REQ"][r] = str
          end

        end
      end

    end
  end
end