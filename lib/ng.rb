# Decrypt Pin
module HSM
  class NG

    # Request
    #   Command           "NG"
    #   Clean PAN         12 - 19 Numeric characters, including check digit (AES)
    #   Delimiter         ; 1 semicolon
    #   Encrypted PIN     "M" + 32 Hexadecimal, output of BA



    def call(client)
      pan = client.gets(';', 20)
      reject("15") if pan.nil?
      pan = pan.chop 
      pinDelim = client.read(1)
      reject("15") unless pinDelim == "M"
      pinCrypted = client.read(32)
      reject("15") unless pinCrypted.length <= 32

      # recreate panwrapped
      panLen = (pan.length - 12).to_s(16)
      panWrapped = (panLen + pan).ljust(32, "0")
      panBytes = panWrapped.unHex
      pinWrapped = pinCrypted.unHex
      pinWrapped = hsmdecrypt(pinWrapped)
      xor = pinWrapped.^(panBytes)
      pinHex = hsmdecrypt(xor).toHex

      # read pin, discard rest
      pinLen = pinHex[1].to_i
      pin = pinHex[2..(1 + pinLen)] # for 0 index

      # create reference num
      # FIXME: there is no spec for how to create this, only that it is derived from encrypting the PAN under the LMK
      reference = hsmencrypt(pan).toHex.to_i(16) # encrypt and convert to number
      reference = reference.to_s[0..11]

      pin = pin.ljust(12, "F")
      payload = "NH00" + pin + reference
      client.write(wrap(payload))
      client.close

    rescue ArgumentError => e
      payload = "NH#{e.message}"
      client.write(wrap(payload))
    rescue RuntimeError , IO::WaitReadable => e
      client.write(wrap(""))
      client.close
    end
  end
end