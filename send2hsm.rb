#!/usr/bin/ruby -I.
require 'socket'
require "config"

begin
  message = ARGV.empty? ? $stdin.read() : ARGV.first()
  s = TCPSocket.new($hostname, $port)
  s.write(wrap(message))
  hexlen = s.read(2)
  len = hexlen.unpack1('n')
  payload = s.read_nonblock(len)
  s.close
  print(payload[$prefixNullCount..-1]) # skip nulls in preamble
rescue Errno::ECONNRESET
 puts("HSM closed connection")
end