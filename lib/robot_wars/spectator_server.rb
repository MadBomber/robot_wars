require "socket"

module RobotWars
  # The browser spectator's HTTP server, on the Ruby standard library
  # alone (no rack/sinatra dependency for one page and a feed). "/"
  # serves the fixed page shell; "/events" is a Server-Sent Events
  # stream that replays the latest published update on connect and then
  # pushes each new one. Each connection gets its own thread; the only
  # state they share are frozen strings and per-subscriber Queues, all
  # handed over under one mutex — server threads never touch the game.
  class SpectatorServer
    attr_reader :host

    # @param html [String] the page served at "/"
    # @param host [String] interface to bind
    # @param port [Integer] TCP port; 0 lets the OS pick a free one
    def initialize(html:, host: "127.0.0.1", port: 0)
      @html = html
      @host = host
      @requested_port = port
      @server = nil
      @thread = nil
      @mutex = Mutex.new
      @subscribers = []
      @client_threads = []
      @latest = nil
      @stopping = false
    end

    def start
      @server = TCPServer.new(@host, @requested_port)
      @thread = Thread.new { accept_loop }
      self
    end

    # The bound port — the OS's pick when constructed with port 0.
    def port
      raise Error, "server not started" unless @server

      @server.addr[1]
    end

    def url = "http://#{host}:#{port}/"

    # Pushes one update to every connected spectator and remembers it
    # as the replay for whoever connects next.
    def publish(message)
      @mutex.synchronize do
        @latest = message.dup.freeze
        @subscribers.each { |queue| queue << @latest }
      end
      self
    end

    def stop
      halt_feeds
      @server&.close
      @thread&.join
      @mutex.synchronize { @client_threads.dup }.each(&:join)
      self
    end

    private

    # Ends every open /events feed: each subscriber's queue gets the
    # stop sentinel AFTER anything already published, so the final
    # update is delivered before the connection closes.
    def halt_feeds
      @mutex.synchronize do
        @stopping = true
        @subscribers.each { |queue| queue << :stop }
      end
    end

    def accept_loop
      loop do
        client = @server.accept
        thread = Thread.new { serve_client(client) }
        @mutex.synchronize { @client_threads << thread }
      end
    rescue IOError, Errno::EBADF
      # stop closed the listening socket out from under accept — the
      # loop's one normal exit.
    end

    def serve_client(client)
      path = read_request_path(client)
      if path == "/"
        client.write(ok_response)
      elsif path == "/events"
        stream_events(client)
      elsif path
        client.write(not_found_response)
      end
    rescue Errno::EPIPE, Errno::ECONNRESET, IOError
      # The browser went away mid-request; nothing left to serve it.
    ensure
      client.close
    end

    # The request path, with the header lines drained so an immediate
    # close can't cut the response short; nil when the client hung up
    # without sending a request.
    def read_request_path(client)
      request_line = client.gets
      return nil unless request_line

      while (line = client.gets)
        break if line.strip.empty?
      end
      request_line.split[1]
    end

    # One spectator's SSE feed: headers, the latest update as instant
    # catch-up, then everything published until the match's final word
    # (or stop). A vanished browser surfaces as a write error, handled
    # by serve_client; either way the subscription dies with the loop.
    def stream_events(client)
      queue = subscribe
      client.write(sse_headers)
      while (message = queue.pop) != :stop
        client.write("data: #{message}\n\n")
      end
    ensure
      unsubscribe(queue)
    end

    def subscribe
      @mutex.synchronize do
        queue = Queue.new
        queue << @latest if @latest
        queue << :stop if @stopping
        @subscribers << queue
        queue
      end
    end

    def unsubscribe(queue)
      @mutex.synchronize { @subscribers.delete(queue) }
    end

    def sse_headers
      "HTTP/1.1 200 OK\r\n" \
        "Content-Type: text/event-stream\r\n" \
        "Cache-Control: no-cache\r\n" \
        "Connection: close\r\n" \
        "\r\nretry: 2000\n\n"
    end

    def ok_response
      response("200 OK", "text/html; charset=utf-8", @html)
    end

    def not_found_response
      response("404 Not Found", "text/plain; charset=utf-8", "not found\n")
    end

    def response(status, content_type, body)
      "HTTP/1.1 #{status}\r\n" \
        "Content-Type: #{content_type}\r\n" \
        "Content-Length: #{body.bytesize}\r\n" \
        "Connection: close\r\n" \
        "\r\n#{body}"
    end
  end
end
