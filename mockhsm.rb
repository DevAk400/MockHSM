require "config"

class MockHSM

  def run() 
    server = TCPServer.new($port)
    puts "Server running on port #{$port}."

    Signal.trap("INT") do
      exit(0)
    end

    loop do # loop while
      client = server.accept
      lead = client.read(2 + $prefixNullCount)
      command = client.read(2).b
      if command.empty?
        client.close
        next
      end
      unless COMMANDS.include?(command)
        puts "Invalid Directive. Closing connection." # log
        client.puts("Error")
        client.close
        next
      end  
      unless IMPLEMENTED.include?(command)
        client.puts("#{command.succ}68")
        client.close
        next
      end
      Thread.new(command, client) { |command, client|
        Module.const_get("HSM::#{command}").new().call(client)
      }
    
    end
  end

end