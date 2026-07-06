# Pin transfer from LMK to ZPK
module HSM
  class JG
 
    # Request
    #   Command           "JG"
    #   Destination ZPK   "S" + 96 Hexadecimal (from output of A0 command)
    #   Mode format       2 Numeric
    #   Clear PAN         12 - 19 Numeric, Primary Account Number
    #   Delimiter         ";" 1 semicolon
    #   PIN block         "M" + 32 Hexadecimal, from BA output



    def call(client)
      zpk = client.read(97)
      reject("15") unless zpk.start_with?("S")
      format = client.read(2)
      pan = client.gets(';', 20)
      reject("15") if pan.nil?
      pan = pan.chop 
      pinStart = client.read(1)
      reject("15") unless pinStart == "M"
      lmkBlock = client.read(32)

      # Recreate panwrapped
      panLen = (pan.length - 12).to_s(16) # PANs have min length of 12. The number that matters is the number of characters past the 12th
      panWrapped = (panLen + pan).ljust(32, "0")
      panBytes = panWrapped.unHex

      # Obtain wrapped pin from LMK encryption
      lmkBlock = lmkBlock.unHex
      lmkBlock = hsmdecrypt(lmkBlock)    
      xor = lmkBlock.^(panBytes)
      pinWrapped = hsmdecrypt(xor)

      # Redo encryption using ZPK 
      iv = zpk[1..16]
      key = zpk[17..-1] # obtain raw key from zpk
      key = key.unHex
      key = hsmdecrypt(key)
      key = key[0..31]
      cipher = OpenSSL::Cipher.new("AES-256-CBC").encrypt
      cipher.key = key
      cipher.iv = iv
      cipher.padding = 0
      zpkEncrypted = cipher.update(pinWrapped) + cipher.final
      xor = zpkEncrypted.^(panBytes)
      cipher = OpenSSL::Cipher.new("AES-256-CBC").encrypt
      cipher.key = key
      cipher.iv = iv
      cipher.padding = 0
      final = cipher.update(xor) + cipher.final
      final = final.toHex
      
      payload = "JH00" + final
      client.write(wrap(payload))
      client.close()

    rescue ArgumentError => e
      payload = "NH#{e.message}"
      client.write(wrap(payload))
    rescue RuntimeError , IO::WaitReadable => e
      client.write(wrap(""))
      client.close
    end
  end
end