# Encrypt Pin
module HSM
  class BA

    # Request
    #   Command           "BA"
    #   Padded PIN        12 Hexchars, PIN padded with 'F's
    #   Clean PAN         12 - 19 Numeric characters, including check digit (AES)
    #   Delimiter         ; 1 semicolon


    
    def call(client)
      pin = client.read(16).gsub(/f/i, "") # remove padding (F)
      reject("15") unless pin.length > 0
      pan = client.read_nonblock(20)
      reject("15") unless pan[-1] == ";"
      pan = pan.chop
      reject("15") unless pan.length.between?(13, 19)

      # wrap pin
      displacement = 14 - pin.length
      padders = ["A", "B", "C", "D", "E", "F"]
      pinFill = []
      displacement.times{
        pinFill << padders.sample
      }
      pinFill = pinFill.join
      randHex = Random.hex(8).upcase
      pinWrapped = "4" + pin.length.to_s(16) + pin + pinFill + randHex

      # wrap pan
      panLen = (pan.length - 12).to_s(16)
      panWrapped = (panLen + pan).ljust(32, "0")
      # prepare for encryption
      pinBytes = pinWrapped.unHex
      panBytes = panWrapped.unHex

      # creating pin block
      pinCrypted = hsmencrypt(pinBytes)
      xor = pinCrypted.^(panBytes)
      final = hsmencrypt(xor)
      final = final.toHex

      payload = "BB00" + "M" + final
      client.write(wrap(payload))
      client.close()

    rescue ArgumentError => e
      payload = "BB#{e.message}"
      client.write(wrap(payload))
    rescue RuntimeError , IO::WaitReadable => e
      client.write(wrap(""))
      client.close
    end
  end
end