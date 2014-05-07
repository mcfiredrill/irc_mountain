# irc_mountain

## websocket recieves CONNECT message

```
socket.send("CONNECT nickname")
```

websocket.rb gets ip address and calculates hostname, then forks off
User.new in a new process:

```
u = User.new('nickname', '129.4.4.22', 'blah.com')
```

User sends these commands to send messages:
# MESSAGE nick;message
# NEWNICK nick;newnick

Redis keys:
irc:stream # incoming messages from irc, sent to webpage for user display
user:irc:send # messages incoming from websocket that user wants to send to irc
users # list of connected users, their nick, ip_address and hostname
