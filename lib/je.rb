# Transfer pin from ZPK to LMK
module HSM
  class JE
    # Request
    #   Command           "JE"
    #   Source ZPK        "S" + 96 Hexadecimal (from output of A0 command)
    #   PIN block         32 Hexadecimal, (AES), from JG output
    #   Mode format       2 Numeric
    #   Clear PAN         12 - 19 Numeric, Primary Account Number
    #   Delimiter         ";" 1 semicolon



    def call(client)
      zpk = client.read(97)
      reject("15") unless zpk.start_with?("S")
      zpkBlock = client.read(32) # keyblock encrypted under zpk
      format = client.read(2)
      pan = client.gets(';', 20)
      reject("15") if pan.nil?
      pan = pan.chop 

      # recreate panwrapped
      panLen = (pan.length - 12).to_s(16) # PANs have min length of 12. The number that matters is the number of characters past the 12th
      panWrapped = (panLen + pan).ljust(32, "0")
      panWrapped = panWrapped.unHex
      
      # Obtain wrapped pin from ZPK encryption
      iv = zpk[1..16]
      key = zpk[17..-1] # obtain raw key from zpk
      key = key.unHex
      key = hsmdecrypt(key)
      key = key[0..31]
      zpkBlock = zpkBlock.unHex
      cipher = OpenSSL::Cipher.new("AES-256-CBC").decrypt
      cipher.key = key
      cipher.iv = iv
      cipher.padding = 0
      zpkDecrypted = cipher.update(zpkBlock) + cipher.final
      xor = zpkDecrypted.^(panWrapped)
      cipher = OpenSSL::Cipher.new("AES-256-CBC").decrypt
      cipher.key = key
      cipher.iv = iv
      cipher.padding = 0
      pinWrapped = cipher.update(xor) + cipher.final

      # Redo encryption using LMK 
      pinCrypted = hsmencrypt(pinWrapped)
      xor = pinCrypted.^(panWrapped)
      final = hsmencrypt(xor)
      final = final.toHex()
      
      payload = "JF00" + final
      client.write(wrap(payload))

    rescue ArgumentError => e
      payload = "NH#{e.message}"
      client.write(wrap(payload))
    rescue RuntimeError , IO::WaitReadable => e
      client.write(wrap(""))
      client.close
    end
  end
end