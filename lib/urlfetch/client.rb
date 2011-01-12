require 'socket'

module Urlfetch

  Address = Struct.new(:host, :port)

  DEFAULT_ADDR = Address.new(host='127.0.0.1', port=10190)

  MAX_CHUNK_SIZE = 1024

  ERROR = 'ERROR'

  NOT_FOUND = 'NOT_FOUND'

  TERMINATOR = "\tEOF\n"

  TERMINATOR_REGEX = Regexp.new(Urlfetch::TERMINATOR<<'$')

  # Instances of this class are raised when a download fails.
  class DownloadError < StandardError
  end

  # Returns a data packet.
  #
  # Params:
  # +args+:: Arbitrary arguments to pack as binary data.
  #
  # Returns:
  # Packed binary data.
  #
  def pack(*args)
    data = String.new
    args.each do |a|
      data << a
    end
    return data
  end
  module_function :pack

  # Creates a command from the given arguments.
  #
  # Params:
  # +args+:: Arbitrary arguments to pack as binary data.
  #
  # Returns:
  # Encoded command.
  #
  def command(*args)
    if args.length == 1
      return args[0]
    end
    command = String.new
    args.slice(0, args.length-1).each do |a|
      command << self.pack(a.length, a)
    end
    command << args[-1]
    return command
  end
  module_function :command

  # Convert first four bytes from a string to an unsigned 32-bit integer.
  #
  # Params:
  # +s+:: A string.
  #
  # Returns:
  # Integer.
  #
  def read_int4(s)
    int = Integer((s[0].ord << 24) +
                  (s[1].ord << 16) +
                  (s[2].ord << 8) +
                  (s[3].ord << 0))
    return int
  end
  module_function :read_int4

  # Encodes headers.
  #
  # Params:
  # +headers+:: Hash with key-value pairs holding the HTTP headers.
  #
  # Returns:
  # Encoded headers.
  #
  def encode_headers(headers)
    if headers.length == 0 then
      return ""
    end
    h = Array.new
    headers.keys.sort.each do |k|
      h << k+': '+headers[k]
    end
    return h.join("\n")
  end
  module_function :encode_headers

  # Decodes headers.
  #
  # Params:
  # +string+:: String containing encoded HTTP headers.
  #
  # Returns:
  # Hash with key-value pairs holding the HTTP headers.
  #
  def decode_headers(string)
    headers = Hash.new
    string.split("\n").map { |h| h.split(": ") }.map { |k,v| headers[k]=v }
    return headers
  end
  module_function :decode_headers

  # Instances of this class represent single clients for the URL Fetch service.
  class URLFetchClient

    # Constructor.
    #
    # Params:
    # +addr+:: An Address instance.
    #
    def initialize(addr=DEFAULT_ADDR)
      @address = addr
      @socket = nil
    end

    # Private method to open a socket to the URL Fetch service.
    def open
      @socket = TCPSocket.new(@address.host, @address.port)
    end
    private :open

    # Closes the socket to the URL Fetch service.
    def close
      if @socket != nil then
        @socket.close
        @socket = nil
      end
    end

    # Starts a fetch call.
    #
    # Params:
    # +url+:: The HTTP/S URL.
    # +payload+:: Body content for a POST or PUT request.
    # +method+:: The HTTP method.
    # +headers+:: Hash holding the HTTP headers as key-value pairs.
    #
    # Returns:
    # A fetch call id.
    #
    def start_fetch(url, payload="", method="get", headers={})
      open if @socket == nil

      method.downcase!

      headers = Urlfetch.encode_headers(headers)

      @socket.write(
        Urlfetch.command("FETCH_ASYNC", method, url, payload, headers))

      res = @socket.read(32)

      if res == ERROR then
        raise DownloadError
      end

      return res
    end

    # Gets the results.
    #
    # Params:
    # +fid+:: The fetch call id.
    # +nowait+:: Boolean which specifies if the client waits for results.
    #
    # Returns:
    # * Status code
    # * Response headers
    # * Response body
    #
    def get_result(fid, nowait=false)

      open if @socket == nil

      @socket.write(
        Urlfetch.command(nowait ? "GET_RESULT_NOWAIT" : "GET_RESULT", fid))

      body = ""

      while data = (@socket.readpartial(MAX_CHUNK_SIZE) rescue nil)
        if body.length == 0 and data then
          status_code = Urlfetch.read_int4(data.slice(0, 4))
          data = data.slice(4, data.length)
        end

        if not data or data == NOT_FOUND
          raise DownloadError
        end

        if data =~ TERMINATOR_REGEX then
          body << data.slice(0, data.length-TERMINATOR.length)
          break
        end

        body << data
      end

      headers, body = body.split("\n\n", 2)

      res = {"status_code"=>status_code,
             "body"=>body,
             "headers"=>Urlfetch.decode_headers(headers)}

      return res
    end

  end  # class URLFetchClient

end  # module Urlfetch
