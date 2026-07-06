# Encrypt Data 
module HSM
  class M0
    
    # Request
    #   Command           "M0"
    #   Mode flag         2 Numeric, "00" for ECB, "01" for CBC, etc..
    #   Input format      1 Numeric, "0" for bin, "1" for hex and "2" for plaintext
    #   Output format     1 Numeric, similar to input format, only values "0" and "1"
    #   Key type          "FFF" (ignored)
    #   Key               "S" + 96 Hexadecimal (from output of A0 command)
    #   IV                32 Hexadecimal (AES), only included if encryption mode requires it (check mode flag)
    #   Message length    4 Hexadecimal. Message length must be a multiple of 16
    #   Message           n Bytes / Hexadecimal / Plaintext, depending on input format flag.



    def call(client)
      mode = client.read_nonblock(2)
      reject("02") unless mode.size == 2
      algorithm = ""
      algorithm = "AES-256-ECB" if mode == "00"
      algorithm = "AES-256-CBC" if mode == "01"
      algorithm = "AES-256-CFB1" if mode == "02" #cfb8 bit
      algorithm = "AES-256-CFB8" if mode == "03" # cfb64 bit
      # Unimplemented codes: '04': Visa Standard Encryption, '05': OFB, '06': CTR, '11': FF1, '13': Visa Format Preserving Encryption
      reject("68") if ["04", "05", "06" "11", "13"].include?(mode)
      reject("02") if algorithm.empty?
      needIV = ["01", "02", "03", "06"].include?(mode)
      
      inputFormat = client.read_nonblock(1) # compare to string later
      reject("03") unless ["0", "1", "2"].include?(inputFormat)

      outputFormat = client.read_nonblock(1) 
      reject("04") unless ["0", "1"].include?(outputFormat)

      keyType = client.read_nonblock(3) # ignored on key block LMK
      reject("68") if keyType != "FFF"

      sKeyBlock = client.read_nonblock(17) # header. get from A0
      reject("15") unless sKeyBlock.start_with?("S")
      keyBlockHeader = sKeyBlock[1..-1]

      encrypted = client.read_nonblock(80).unHex
      begin
        decrypted = hsmdecrypt(encrypted, keyBlockHeader[0..11])  # only need 12 bytes for gcm encryption
      rescue
        reject("10")
      end
      bitSize = decrypted[0..1].unpack1("n")
      secretKey = decrypted[2..(1 + bitSize / 8)]

      if needIV
        hexIV = client.read_nonblock(32)
        iv = hexIV.unHex
      end

      len = client.read_nonblock(4).to_i(16)
      reject("06") if len > 32000
      reject("35") unless (len % 16).zero?
      message = client.read_nonblock(len).b
      message = message.unHex if inputFormat == "1"

      cipher = OpenSSL::Cipher.new(algorithm).encrypt  # Create cipher in selected encryption mode
      cipher.key = secretKey
      cipher.iv = iv if needIV
      cipher.padding = 0
      encrypted = cipher.update(message) + cipher.final
      encrypted = encrypted.b
      # hex if output mode requires
      encrypted = encrypted.toHex if outputFormat == "1"
      # output
      outLen = [encrypted.size()].pack("n").toHex

      payload = "M100#{hexIV}#{outLen}#{encrypted}"
      client.write(wrap(payload))
      client.close
    rescue ArgumentError => e
      payload = "M1#{e.message}"
      client.write(wrap(payload))
    rescue RuntimeError , IO::WaitReadable => e
      client.write(wrap(""))
      client.close
    end

  end
end

