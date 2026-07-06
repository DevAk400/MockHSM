# Key Generation Command
module HSM
  class A0


    # Request
    #   Command           "A0"
    #   Mode              1 Numeric, (0 for key generation)
    #   Key type          3 Hexadecimal, "FFF" (ignored)
    #   Key scheme        1 Alphanumeric
    #   Delimiter         "#", required for keyblock format
    #   Key usage         2 Alphanumeric
    #   Algorithm         2 Alphanumeric, "A3" only currently supported mode
    #   Mode of use       1 Alphanumeric
    #   Key version num   2 Numeric
    #   Exportability     1 Alphanumeric
    #   Number of 
    #   optional blocks   2 Alphanumeric


    def call(client)
      mode = client.read(1)
      reject("15") unless mode == "0"

      keyType = client.read(3)
      reject("15") unless keyType == "FFF"

      keyScheme = client.read(1)
      reject("68") unless keyScheme == "S"

      delimiter = client.read(1)
      reject("15") unless delimiter == "#"

      usage = client.read(2)
      # FIXME: validate against the key usage table in the programmers guide if you wish for more accuracy

      algorithm = client.read(2)
      reject("15") unless  "ADEHRST".include?(algorithm[0])
      reject("68") unless  algorithm == "A3" # algorithm = A3 (AES-256)

      useMode = client.read(1)
      reject("15") unless  "BCDEGNSVX".include?(useMode)
      reject("68") unless  useMode == "N" 

      versionNum = client.read(2)
      reject("15") unless  versionNum.scan(/\D/)

      exportability = client.read(1)
      reject("15") unless  "ENS".include?(exportability)

      optBlock = client.read(2)
      reject("15") unless  optBlock.scan(/\D/)
      reject("68") unless  optBlock == "00" 

      keyLen = 256 / 8 # bits FIXME: only supports algorithm A3
      secretKey = Random.bytes(keyLen).b
      padding = Random.bytes(40-2-keyLen)
      keySize = [keyLen * 8].pack("n")
      lmkID = "00"
      keyBlockHeader = "10096#{usage}A#{useMode}#{versionNum}#{exportability}#{optBlock}#{lmkID}"
      encrypted = hsmencrypt(keySize + secretKey + padding, keyBlockHeader[0..11]).toHex
      
      # create key check value (KCV)
      nulls = "0" * 16
      cipher = OpenSSL::Cipher.new("AES-256-ECB").encrypt
      cipher.key = $lmk
      checkValEncrypted = cipher.update(nulls) + cipher.final
      checkValHex = checkValEncrypted.toHex
      checkVal = checkValHex[0..5]

      response = "A100S" + keyBlockHeader + encrypted + checkVal
      response.upcase!

      client.write(wrap(response))

    rescue ArgumentError => e
      payload = "A1#{e.message}"
      client.write(wrap(payload))
    rescue RuntimeError , IO::WaitReadable => e
      client.write(wrap(""))
      client.close
   end
  end
end