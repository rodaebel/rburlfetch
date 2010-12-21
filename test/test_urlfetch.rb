require 'test/unit'

class TestUrlfetchClient < Test::Unit::TestCase

  def test_pack
    require 'urlfetch'

    assert_equal("\003foo", Urlfetch.pack(3, 'foo'))
  end

  def test_command
    require 'urlfetch'

    assert_equal("foo", Urlfetch.command('foo'))
    assert_equal("\003foobar", Urlfetch.command('foo', 'bar'))
    assert_equal("\003foo\004testbar", Urlfetch.command('foo', 'test', 'bar'))
  end

  def test_read_int4
    require 'urlfetch'

    assert_equal(400, Urlfetch.read_int4("\000\000\001\220"))
  end

  def test_headers
    require 'urlfetch'

    headers = {'Content-Type'=>'text/plain', 'X-Custom-Header'=>'foobar'}

    assert_equal(
      "Content-Type: text/plain\nX-Custom-Header: foobar",
      Urlfetch.encode_headers(headers))

    assert_equal(
      {'Content-Type'=>'text/plain', 'X-Custom-Header'=>'foobar'},
      Urlfetch.decode_headers(Urlfetch.encode_headers(headers)))
  end

  def test_fetch_call
    require 'urlfetch'

    # Create an address
    addr = Urlfetch::Address.new(host='127.0.0.1', port=10190)

    # Instatiate a client
    client = Urlfetch::URLFetchClient.new(addr)

    # Start a single fetch call
    fid = client.start_fetch("http://www.ruby-lang.org")

    assert_equal(32, fid.length)

    # Get the result
    result = client.get_result(fid)

    # Close the client
    client.close

    assert_equal(200, result["status_code"])
  end

  def test_fetch_call_nowait
    require 'urlfetch'

    # Create an address
    addr = Urlfetch::Address.new(host='127.0.0.1', port=10190)

    # Instatiate a client
    client = Urlfetch::URLFetchClient.new(addr)

    # Start a single fetch call
    fid = client.start_fetch("http://www.ruby-lang.org")

    assert_equal(32, fid.length)

    begin
      # Get the result
      result = client.get_result(fid, nowait=true)
    rescue Urlfetch::DownloadError
      # Retry, but now wait for the result
      result = client.get_result(fid)
    ensure
      # Close the client
      client.close
    end

    assert_equal(200, result["status_code"])
  end

end
