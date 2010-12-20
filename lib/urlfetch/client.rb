require 'socket'

module Urlfetch

  Address = Struct.new(:host, :port)

  DEFAULT_ADDR = Address.new(host='127.0.0.1', port=10190)

  MAX_CHUNK_SIZE = 1024

  ERROR      = 'ERROR'

  NOT_FOUND  = 'NOT_FOUND'

  TERMINATOR = "\tEOF\n$"

  # Instances of this class are raised when a download fails.
  class DownloadError < StandardError
  end

  # Returns a data packet.
  def self.pack(*args)
    data = String.new
    args.each do |a|
      data << a
    end
    return data
  end

  # Creates a command from the given arguments.
  def self.command(*args)
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

  # Encodes headers.
  def self.encode_headers(headers)
    if headers.length == 0 then
      return ""
    end
    h = Array.new
    headers.keys.sort.each do |k|
      h << k+': '+headers[k]
    end
    return h.join("\n")
  end

  # Instances of this class represent single clients for the URL Fetch service.
  class URLFetchClient

    # Constructor.
    # Params:
    # +addr+:: An Address instance
    def initialize(addr=DEFAULT_ADDR)
      @address = addr
      @socket = nil
    end

    def open
      @socket = TCPSocket.new(@address.host, @address.port)
    end
    private :open

    def close
      if @socket != nil then
        @socket.close
        @socket = nil
      end
    end

    def start_fetch(url, payload="", method="get", headers={})
      if @socket == nil then
        open
      end

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

    def get_result(fid, nowait=false)

      if @socket == nil then
        open
      end

      if nowait then
        @socket.write(Urlfetch.command("GET_RESULT_NOWAIT", fid))
      else
        @socket.write(Urlfetch.command("GET_RESULT", fid))
      end

      while data = (@socket.readpartial(MAX_CHUNK_SIZE) rescue nil)
        (body||="") << data

        if data =~ Regexp.new(Urlfetch::TERMINATOR) then
          break
        end
      end
      return body
    end

  end  # class URLFetchClient

end  # module Urlfetch
