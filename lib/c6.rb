# Random hex bytes command
module HSM
  class C6
    # Request
    #   Command           "C6"

    
    def call(client)
        randHex = Random.hex(8).upcase()
        payload = "C700#{randHex}"
        client.write(wrap(payload)) 
        client.close
    end
  end
end

