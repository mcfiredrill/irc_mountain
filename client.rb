require './irc'
require 'redis'

r = Redis.new

irc = IRC.new({
  :server => "irc.freenode.net",
  :port => 6667, # optional
  :channel => "#datafruitsouth",
  :nick => "rutbut",
  :real => "Rubot", #optional
  :debug => true # optional
})
 
### listeners
 
irc.on("connect") do
  # called when you have registered on the server
end
 
irc.on("join") do |channel, nick|
  # called when a user joins a channel
  r.publish "irc:stream", "#{nick} has joined #{channel}"
end
 
irc.on("part") do |channel, nick|
  # called when a user leaves a channel
end
 
irc.on("nick") do |nick, new_nick|
  # called when a user changes their nick
end
 
irc.on("message") do |channel, nick, message|
  # called when a user sends a message to a channel
  msg = "#{nick} #{message}"
  puts msg
  r.publish "irc:stream", msg
end
 
irc.on("pm") do |nick, message|
  # called when a user sends a private message to you
end
 
### methods
 
irc.connect # connect to the server
