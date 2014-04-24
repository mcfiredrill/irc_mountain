# https://gist.github.com/henderjon/2345095

require 'socket'
require 'redis'

class IRC
  def initialize(info)
    @server = info[:server]
    @port = info[:port] || 6667
    @password = info[:password]
    @nick = info[:nick]
    @channel = info[:channel]
    @real = info[:real] || "Ruby IRC Bot"
    @debug = info[:debug] || false
    @callbacks = {
      "connect" => [],
      "join" => [],
      "part" => [],
      "nick" => [],
      "message" => [],
      "pm" => []
    }
    on("connect") { join @channel }
  end

  def send(command)
    puts "---> #{command}" if @debug
    @irc.send "#{command}\n", 0
  end

  def handle_server_input(s)
    case s.strip
      when /^PING :(.+)$/i
        puts "[ Server ping ]" if @debug
        send "PONG :#{$1}"
      when /^:(.+?)!(.+?)@(.+?)\sPRIVMSG\s.+\s:[\001]PING (.+)[\001]$/i
        puts "[ CTCP PING from #{$1}!#{$2}@#{$3} ]" if @debug
        send "NOTICE #{$1} :\001PING #{$4}\001"
      when /^:(.+?)!(.+?)@(.+?)\sPRIVMSG\s.+\s:[\001]VERSION[\001]$/i
        puts "[ CTCP VERSION from #{$1}!#{$2}@#{$3} ]" if @debug
        send "NOTICE #{$1} :\001VERSION Ruby-irc v0.042\001"
      when /:(.+?)\sMODE\s(.+?)\s:\+i/i
        # connect
        puts "connect callbacks"
        @callbacks["connect"].each { |callback| callback.call() }
      when /^:(.+?)!(.+?)@(.+?)\sPRIVMSG\s(.+)\s:(.+)$/i
        # message
        # $1 = user; $4 = room; $5 = message
        if($4 == @nick)
          @callbacks["pm"].each { |callback| callback.call($1, $5) }
        else
          @callbacks["message"].each { |callback| callback.call($4, $1, $5) }
        end
      when /^:(.+?)!(.+?)@(.+?)\sJOIN\s:(.+?)$/i
        # join
        # $1 = user; $4 = room
        puts "join callbacks"
        @callbacks["join"].each { |callback| callback.call($4, $1) }
      when /^:(.+?)!(.+?)@(.+?)\sPART\s(.+?)$/i
        # part
        # $1 = user; $4 = room
        @callbacks["part"].each { |callback| callback.call($4, $1) }
      when /^:(.+?)!(.+?)@(.+?)\sNICK\s:(.+?)$/i
        # change nick
        # $1 = nick; $4 = new_nick
        @callbacks["nick"].each { |callback| callback.call($1, $4) }
      else
        puts "nothing matched!"
        puts s if @debug
    end
  end

  def main
    r = Redis.new
    threads = []

    threads << Thread.new do
      while true
        ready = select([@irc, $stdin], nil, nil, nil)
        next if !ready
        for s in ready[0]
          if s == $stdin
            # allow user to send command via STDIN in debug
            if @debug
              return if $stdin.eof
              s = $stdin.gets
              send s
            end
          elsif s == @irc
            return if @irc.eof
            s = @irc.gets
            puts "run callbacks..."
            handle_server_input(s)
          end
        end
      end
    end
    threads << Thread.new do
      while true
        cmd = r.blpop("irc:send")
        puts cmd
        send cmd.last
      end
    end
    threads.each { |t| t.join }
  end

  def connect
    @irc = TCPSocket.open(@server, @port)
    send "PASS #{@password}" if @password
    send "USER #{@real} hostname servername :#{@real}"
    send "NICK #{@nick}"
    begin
      main
    rescue Interrupt
      puts "interrupted"
      @irc.close
    rescue Exception => e
      puts e.message
      print e.backtrace.join("\n")
      retry
    end
  end

  def on(listener, &block)
    @callbacks[listener].push(block)
  end

  def join(channel)
    send "JOIN #{channel}"
  end

  def say(who, msg)
    send "PRIVMSG #{who} #{msg}"
  end
end
