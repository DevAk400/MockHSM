# Echo command - echoes message
module HSM
  class B2

    # Request
    #   Command           "B2"
    #   Length            4 Hexadecimal, Length of message
    #   Data              n Bytes, (can be plaintext too)


    
    def call(client)
        hexLength = client.read_nonblock(4)
        raise() if hexLength.size() != 4
        len = hexLength.to_i(16)
        raise() if len.zero? # if not valid hex, result will be 0
        message = client.read(len)
        payload = "B300#{message}"
        client.write(wrap(payload))
        client.close
    rescue RuntimeError , IO::WaitReadable
      client.write(wrap("B315"))
      client.close()
    end
    
  end
end