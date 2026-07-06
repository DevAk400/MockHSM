require("securerandom")
require("socket")
require("base64")
require("openssl")


$hostname = "127.0.0.1"
$port = 9000
$prefixNullCount = 4


def wrap(message)
  preamble = "\0" * $prefixNullCount
  [message.size() + $prefixNullCount].pack("n").b + preamble.b + message.b
end

def reject(code)
  raise ArgumentError.new(code)
end

def hsmencrypt(message, iv=$lmkiv)
  cipher = OpenSSL::Cipher.new("AES-256-GCM").encrypt
  cipher.key = $lmk
  cipher.iv = iv
  cipher.padding = 0
  cipher.auth_data = $tag
  encrypted = cipher.update(message)
end

def hsmdecrypt(message, iv=$lmkiv)
  cipher = OpenSSL::Cipher.new("AES-256-GCM").decrypt
  cipher.key = $lmk
  cipher.iv = iv
  cipher.padding = 0
  cipher.auth_data = $tag
  decrypted = cipher.update(message)
end

class String
  def toHex()
    self.unpack1("H*").upcase
  end

  def unHex()
    [self].pack("H*").b
  end

  def ^(b)
    self.bytes.zip(b.bytes).collect{|x,y|(x^y).chr}.join("")
  end
end


Dir["./lib/*.rb"].each {|file|
  require file.delete_prefix("./").delete_suffix(".rb")
}  




COMMANDS = ["B2", "C0", "C6", "N0", "M0", "M2", "A0", "BA", "NG", "JE", "JG"] # fill with list of all commands
IMPLEMENTED = HSM.constants.collect{|x| x.to_s}

$lmk = ["49ab6f6e7fe255d2b2c553fdaec8eaa8b4439b4e7e4fa6f7be41442032451c6b"].pack("H*") # local master key
$lmkiv = "_\xD5\xE9\xF5~\xFC\x9B_Lk|D"
$tag = "Hello"
$pinlen = 12


