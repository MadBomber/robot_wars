require "socket"

module RobotWars
  # A tiny HTTP server for the browser spectator view, on the Ruby
  # standard library alone (no rack/sinatra dependency for one page).
  # It serves a single fixed HTML document — static content, so the
  # accept loop's background thread shares no mutable state with the
  # match running on the main thread. Requests are handled one at a
  # time, which is plenty for a localhost page.
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

    def stop
      @server&.close
      @thread&.join
      self
    end

    private

    def accept_loop
      loop { handle(@server.accept) }
    rescue IOError, Errno::EBADF
      # stop closed the listening socket out from under accept — the
      # loop's one normal exit.
    end

    def handle(client)
      path = read_request_path(client)
      client.write(path == "/" ? ok_response : not_found_response) if path
    rescue Errno::EPIPE, Errno::ECONNRESET
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
