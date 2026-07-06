# Random hex bytes command
module HSM
  class N0

    # Request
    #   Command               "N0"
    #   Random value length   3 Numeric, any value from "001" to "256"


    
    def call(client)
      v3 = client.read_nonblock(3)
      raise() if v3.size() != 3 or !v3.scan(/\D/).empty?
      len = v3.to_i()
      raise unless (1..256).include?(len)
      randBytes = Random.bytes(len)
      client.write(wrap("N100#{randBytes}")) 
      client.close
    rescue RuntimeError , IO::WaitReadable
      client.write(wrap("N101"))
      client.close
    end
  end
end

