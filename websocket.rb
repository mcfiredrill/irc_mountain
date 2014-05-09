require 'em-websocket'
require 'em-hiredis'
require 'resolv'
require './client'

EM.run {
  @channel = EM::Channel.new

  @redis = EM::Hiredis.connect
  puts 'subscribing to irc:stream'
  @redis.pubsub.subscribe('irc:stream'){ |message|
    puts "redis -> #{message}"
    @channel.push message
  }

  EM::WebSocket.run(:host => "0.0.0.0", :port => 3333) do |ws|
    ws.onopen { |handshake|
      puts "WebSocket connection open"
      puts ws.inspect
      @remote_ip = ws.remote_ip
      puts "ip: #{@remote_ip}"
      @hostname = handshake.headers["Host"]
      puts "hostname: #{@hostname}"

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
      command_type = msg.split(' ').first
      case command_type
      when 'MESSAGE'
        puts 'sending message...'
        user = msg.split('MESSAGE ').last.split(';').first
        message = msg.split(' ').last.split(';').last
        puts "#{user}: #{message}"
        ws.send "#{user};#{message}"
        @redis.publish("#{user}:irc:send", "#{message}")
      when 'CONNECT'
        puts 'connecting...'
        nick = msg.split(' ').last
        ip = ws.remote_ip
        hostname = Resolv.getname ip
        pid = fork do
          Signal.trap("HUP") { puts "Ouch!"; exit }
          Client.new nick, ip, hostname
        end
        @redis.hset 'pids', nick, pid
      when 'DISCONNECT'
        puts 'disconnecting...'
        nick = msg.split(' ').last
        @redis.hget 'pids', nick do |pid|
          Process.kill "HUP", pid.to_i
        end
      else
        puts 'unknown command type'
      end
    }
  end
}
