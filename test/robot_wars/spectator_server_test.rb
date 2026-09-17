require "test_helper"
require "socket"
require "timeout"

class RobotWars::SpectatorServerTest < Minitest::Test
  HTML = "<html><body>arena</body></html>".freeze

  # A scripted client socket for exercising request handling in
  # isolation — no real network, and it can hang up whenever the
  # script says so.
  class FakeClient
    attr_reader :written, :closed

    def initialize(lines: [], write_error: nil)
      @lines = lines
      @write_error = write_error
      @written = +""
      @closed = false
    end

    def gets = @lines.shift

    def write(data)
      raise @write_error if @write_error

      @written << data
    end

    def close = @closed = true
  end

  def serve(html: HTML)
    server = RobotWars::SpectatorServer.new(html: html).start
    yield server
  ensure
    server.stop
  end

  def request(server, path)
    TCPSocket.open(server.host, server.port) do |socket|
      socket.write("GET #{path} HTTP/1.1\r\nHost: #{server.host}\r\n\r\n")
      socket.read
    end
  end

  def test_serves_the_page_at_the_root_path
    serve do |server|
      response = request(server, "/")

      assert_includes response, "HTTP/1.1 200 OK"
      assert_includes response, "Content-Type: text/html; charset=utf-8"
      assert_includes response, "Content-Length: #{HTML.bytesize}"
      assert response.end_with?(HTML)
    end
  end

  def test_any_other_path_is_not_found
    serve do |server|
      assert_includes request(server, "/favicon.ico"), "HTTP/1.1 404 Not Found"
    end
  end

  def test_port_zero_binds_an_os_assigned_port_reported_in_the_url
    serve do |server|
      assert_predicate server.port, :positive?
      assert_equal "http://127.0.0.1:#{server.port}/", server.url
    end
  end

  def test_port_before_start_raises
    server = RobotWars::SpectatorServer.new(html: HTML)

    assert_raises(RobotWars::Error) { server.port }
  end

  def test_stop_shuts_the_server_down
    server = RobotWars::SpectatorServer.new(html: HTML).start
    port = server.port
    server.stop

    assert_raises(Errno::ECONNREFUSED) { TCPSocket.open("127.0.0.1", port) { nil } }
  end

  def test_stop_before_start_is_harmless
    RobotWars::SpectatorServer.new(html: HTML).stop
  end

  def test_a_client_that_hangs_up_before_requesting_gets_nothing
    client = FakeClient.new(lines: [])
    RobotWars::SpectatorServer.new(html: HTML).send(:serve_client, client)

    assert_empty client.written
    assert client.closed
  end

  def test_headers_are_drained_even_when_the_client_omits_the_blank_line
    client = FakeClient.new(lines: ["GET / HTTP/1.1\r\n", "Host: here\r\n"])
    RobotWars::SpectatorServer.new(html: HTML).send(:serve_client, client)

    assert_includes client.written, "200 OK"
    assert client.closed
  end

  def test_a_client_that_vanishes_mid_response_is_shrugged_off
    client = FakeClient.new(lines: ["GET / HTTP/1.1\r\n", "\r\n"], write_error: Errno::EPIPE)
    RobotWars::SpectatorServer.new(html: HTML).send(:serve_client, client)

    assert client.closed
  end

  def test_the_server_survives_a_broken_request_and_keeps_serving
    serve do |server|
      TCPSocket.open(server.host, server.port) { nil }

      assert_includes request(server, "/"), "200 OK"
    end
  end

  # --- The /events SSE feed -------------------------------------------

  def open_events(server)
    socket = TCPSocket.new(server.host, server.port)
    socket.write("GET /events HTTP/1.1\r\nHost: #{server.host}\r\n\r\n")
    socket
  end

  # Reads one "data: ..." SSE frame, skipping headers and other fields.
  def next_data_frame(socket)
    Timeout.timeout(5) do
      while (line = socket.gets)
        return line.delete_prefix("data: ").chomp if line.start_with?("data: ")
      end
      nil
    end
  end

  def test_a_subscriber_first_catches_up_on_the_latest_update_then_gets_new_ones
    serve do |server|
      server.publish("turn-1")
      socket = open_events(server)

      assert_equal "turn-1", next_data_frame(socket)

      server.publish("turn-2")
      assert_equal "turn-2", next_data_frame(socket)
      socket.close
    end
  end

  def test_the_feed_declares_itself_an_event_stream
    serve do |server|
      socket = open_events(server)
      server.publish("x")

      headers = +""
      Timeout.timeout(5) { headers << socket.gets until headers.end_with?("\r\n\r\n") }

      assert_includes headers, "Content-Type: text/event-stream"
      socket.close
    end
  end

  def test_every_subscriber_receives_every_update
    serve do |server|
      first = open_events(server)
      second = open_events(server)
      # Wait until both subscriptions are registered before publishing.
      Timeout.timeout(5) { sleep 0.01 until subscriber_count(server) >= 2 }

      server.publish("both")

      assert_equal "both", next_data_frame(first)
      assert_equal "both", next_data_frame(second)
      first.close
      second.close
    end
  end

  def test_a_subscriber_connected_before_any_update_waits_for_the_first
    serve do |server|
      socket = open_events(server)
      Timeout.timeout(5) { sleep 0.01 until subscriber_count(server).positive? }

      server.publish("first")

      assert_equal "first", next_data_frame(socket)
      socket.close
    end
  end

  def test_stop_ends_every_open_feed
    server = RobotWars::SpectatorServer.new(html: HTML).start
    server.publish("only")
    socket = open_events(server)
    assert_equal "only", next_data_frame(socket)

    Timeout.timeout(5) { server.stop }

    assert_nil next_data_frame(socket)
    socket.close
  end

  def test_a_subscription_arriving_during_stop_is_told_to_stop_immediately
    server = RobotWars::SpectatorServer.new(html: HTML)
    server.stop

    queue = server.send(:subscribe)

    assert_equal :stop, queue.pop
  end

  private

  def subscriber_count(server)
    server.instance_variable_get(:@mutex).synchronize do
      server.instance_variable_get(:@subscribers).size
    end
  end
end
