require 'em-websocket'
require 'em-hiredis'

EM.run {
  @channel = EM::Channel.new

  @redis = EM::Hiredis.connect
  puts 'subscribing to redis'
  @redis.pubsub.subscribe('irc:stream'){ |message|
    puts "redis ->  #{message}"
    @channel.push message
  }

  EM::WebSocket.run(:host => "0.0.0.0", :port => 3333) do |ws|
    ws.onopen { |handshake|
      puts "WebSocket connection open"

      # Access properties on the EM::WebSocket::Handshake object, e.g.
      # path, query_string, origin, headers

      # Publish message to the client
      ws.send "Hello Client, you connected to #{handshake.path}"
      puts 'subscribing to channel'
      sid = @channel.subscribe do |msg|
        puts "sending: #{msg}"
        ws.send msg
    end
    }

    ws.onclose { puts "Connection closed" }

    ws.onmessage { |msg|
      puts "Recieved message: #{msg}"
      ws.send "Pong: #{msg}"
      @redis.rpush("irc:send","PRIVMSG #datafruitsouth :#{msg}")
    }
  end
}
