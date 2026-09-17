require "test_helper"
require "socket"

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
    RobotWars::SpectatorServer.new(html: HTML).send(:handle, client)

    assert_empty client.written
    assert client.closed
  end

  def test_headers_are_drained_even_when_the_client_omits_the_blank_line
    client = FakeClient.new(lines: ["GET / HTTP/1.1\r\n", "Host: here\r\n"])
    RobotWars::SpectatorServer.new(html: HTML).send(:handle, client)

    assert_includes client.written, "200 OK"
    assert client.closed
  end

  def test_a_client_that_vanishes_mid_response_is_shrugged_off
    client = FakeClient.new(lines: ["GET / HTTP/1.1\r\n", "\r\n"], write_error: Errno::EPIPE)
    RobotWars::SpectatorServer.new(html: HTML).send(:handle, client)

    assert client.closed
  end

  def test_the_server_survives_a_broken_request_and_keeps_serving
    serve do |server|
      TCPSocket.open(server.host, server.port) { nil }

      assert_includes request(server, "/"), "200 OK"
    end
  end
end
