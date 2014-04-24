require 'cinch'
require 'redis'

r = Redis.new

irc = Cinch::Bot.new do
  configure do |c|
    c.server = "irc.esper.net"
    #c.port = 6667, # optiona
    c.channels = ["#datafruitseast"]
    c.nick = "rutbutbutt"
    #c.real = "Rubot", #optiona
    #c.debug = true # optiona
  end

  on :message do |message|
    # called when a user sends a message to a channel
    msg = "#{message.user.nick} #{message.message}"
    puts msg
    r.publish "irc:stream", msg
  end

  #on :join do |channel, nick|
    # called when a user joins a channel
  #  r.publish "irc:stream", "#{nick} has joined #{channel}"
  #end
end

irc.start
