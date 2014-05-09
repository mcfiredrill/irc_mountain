require 'cinch'
require 'redis'

class Client
  CHANNEL = "#datafruitsouth"

  def initialize nick, ip_address, hostname
    irc = Cinch::Bot.new do
      configure do |c|
        c.server = "irc.esper.net"
        c.channels = [ CHANNEL ]
        c.nick = nick
        c.webirc = true
        c.hostname = hostname
        c.ip = ip_address
      end

      on :message do |message|
        msg = "#{message.user.nick};#{message.message}"
        puts "saw msg on irc: #{msg}, publishing to irc:stream"
        redis = Redis.new
        redis.publish "irc:stream", msg
      end

      t = Thread.new do
        puts 'new thread'
        loop {
          puts 'in da loop'
          redis = Redis.new
          redis.subscribe "#{nick}:irc:send" do |on|
            on.subscribe do
              puts "subscribed to #{nick}:irc:send"
            end
            on.message do |channel, message|
              puts "got message from irc:send: #{message}"
              Channel(CHANNEL).send(message.split(';').last)
            end
          end
        }
      end
    end

    irc.start
  end
end
