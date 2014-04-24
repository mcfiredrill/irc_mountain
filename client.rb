require 'cinch'
require 'redis'

CHANNEL = "#datafruitsnorth"

$r1 = Redis.new
$r2 = Redis.new

irc = Cinch::Bot.new do
  configure do |c|
    c.server = "irc.esper.net"
    c.channels = [ CHANNEL ]
    c.nick = "rutbutbutt"
  end

  on :message do |message|
    msg = "#{message.user.nick};#{message.message}"
    puts "saw msg on irc: #{msg}, publishing to irc:stream"
    $r1.publish "irc:stream", msg
  end

  t = Thread.new do
    loop {
      $r2.subscribe "irc:send" do |on|
        on.subscribe do
          puts 'subscribed'
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
