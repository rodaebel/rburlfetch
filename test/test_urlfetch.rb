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

  def test_headers
    require 'urlfetch'

    headers = {'Content-Type'=>'text/plain', 'X-Custom-Header'=>'foobar'}

    assert_equal(
      "Content-Type: text/plain\nX-Custom-Header: foobar",
      Urlfetch.encode_headers(headers))
  end

  def test_client
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
  end

end
