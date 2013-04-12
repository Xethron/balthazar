#!/usr/bin/env ruby

require './commands.rb'

# Class to handle IRC commands
class IRCSubs
    def initialize( status, config, output, irc, timer )
        @status     = status
        @config     = config
        @output     = output
        @irc        = irc
        @timer      = timer

        @cmd        = Commands.new( status, config, output, irc, timer, 0 )
		@whois		= Hash.new
    end

    # Functions that are called when actions are detected from IRC.
    def kick( nick, user, host, channel, kicked, reason )
        @output.std( nick + " kicked " + kicked + " from " + channel + ". (" + reason + ")\n" )

        # Check if we need to resend join
        if( @config.nick == kicked && @config.rejoin )
            @timer.action( @config.rejointime, "@irc.join( '#{channel}' )" )
        end

        # Check for plugin hooks
        @status.plugins.each_key do |key|
            if( @status.getplugin( key ).respond_to?( "kicked" ) )
                @status.getplugin( key ).kicked( nick, user, host, channel, kicked, reason )
            end
        end
    end

    def notice( nick,  user,  host,  to,  message )
        @status.plugins.each_key do |key|
            if( @status.getplugin( key ).respond_to?( "noticed" ) )
                @status.getplugin( key ).noticed( nick,  user,  host,  to,  message )
            end
        end
    end

    def join( nick, user, host, channel )
        @status.plugins.each_key do |key|
            if( @status.getplugin( key ).respond_to?( "joined" ) )
                @status.getplugin( key ).joined( nick, user, host, channel )
            end
        end
    end

	def partreason( nick, user, host, channel, reason )
		@status.plugins.each_key do |key|
			if( @status.getplugin( key ).respond_to?( "partedreason" ) )
				@status.getplugin( key ).partedreason( nick, user, host, channel, reason )
			end
		end
	end

	def part( nick, user, host, channel, reason )
        @status.plugins.each_key do |key|
            if( @status.getplugin( key ).respond_to?( "parted" ) )
                @status.getplugin( key ).parted( nick, user, host, channel, reason )
            end
        end
    end

    def quit( nick, user, host, message )
        @status.plugins.each_key do |key|
            if( @status.getplugin( key ).respond_to?( "quited" ) )
                @status.getplugin( key ).quited( nick, user, host, message )
            end
        end
    end
	
	def rename( nick, user, host, newnick )
		if ((nick == @status.nick)&&(user == @status.user)&&(host == @status.host))
			@status.nick( newnick )
			@output.good( "Renamed to: #{newnick}\n" )
		end
		@status.plugins.each_key do |key|
			if( @status.getplugin( key ).respond_to?( "renamed" ) )
				@status.getplugin( key ).renamed( nick, user, host, newnick )
			end
		end
	end

    def privmsg( nick, user, host, from, message )

        # Check if the received message is a bot command
        cmd = @config.command
        if( message =~ /^#{cmd}/ )
            @cmd.process( nick, user, host, from, message.gsub( /^#{cmd}/, "" ) )
        else

            # If not a command, check for plugins with message hook
            @status.plugins.each_key do |key|
                if( @status.getplugin( key ).respond_to?( "messaged" ) )
                    @status.getplugin( key ).messaged( nick, user, host, from, message )
                end
            end
        end
    end
	
	def raw( code, string )
		
		#Check if response is part of a Whois
		if(code==1)
			if( string =~ /.+ (.+?)!(.+?)@(.+)/ )
				@status.nick( $1 )
				@status.user( $2 )
				@status.host( $3 )
			end
		elsif(code==4)
			if( string =~ /^(.+?) .+/ )
				@status.server( $1 )
			end
		elsif(code==396)
			if( string =~ /^(.+?) :.+/ )
				@status.host( $1 )
			end
		elsif ([311,319,320,312,330,307,317,671,310,313,401,318].include?(code))
			if (code==311) #Ident Details
				if( string =~ /^(.+?) (.+?) (.+?) \* :(.+)/ )
					#User Host Full-Name
					addwhois($1,"user", $2)
					addwhois($1,"host", $3)
					addwhois($1,"name", $4)
				else
					rawunknown( "Ident Details ", code, string )
				end
			elsif(code==319) #Channel List
				if( string =~ /^(.+?) :(.+)/ )
					addwhois($1, "chan", $2)
				else
					rawunknown( "Channel List ", code, string )
				end
			elsif(code==320) #IRC Client Info
				if( string =~ /^(.+?) :is using (.+)/ )
					addwhois($1, "client", $2)
				else
					rawunknown( "Client Info ", code, string )
				end
			elsif(code==312) #Server Address & Server Name
				if( string =~ /^(.+?) (.+?) :(.+)/ )
					addwhois($1, "servaddr", $2)
					addwhois($1, "servname", $3)
				else
					rawunknown( "Server Address & Name ", code, string )
				end
			elsif(code==330) #Authentication
				if( string =~ /^(.+?) (.+?) :is logged in as/ )
					addwhois($1, "auth", $2)
				else
					rawunknown( "Authentication ", code, string )
				end
			elsif(code==307) #Registered TRUE
				if( string =~ /^(.+?) :.+/ )
					addwhois($1, "reg", 1)
				else
					rawunknown( "Registered ", code, string )
				end
			elsif(code==317) #Idle Time
				if( string =~ /^(.+?) (\d+) (\d+) :.+/ )
					addwhois($1, "idle", $2.to_i)
					addwhois($1, "online", $3.to_i)
				elsif( string =~ /^(.+?) (\d+) :.+/ )
					addwhois($1, "idle", $2.to_i)
				else
					rawunknown( "Idle Time ", code, string )
				end
			elsif(code==617) #Secure Connection
				if( string =~ /^(.+?) :is using a secure connection/ )
					addwhois($1, "secure", 1)
				else
					rawunknown( "Secure? ", code, string )
				end
			elsif(code==310) #Available for help (IRC OP)
				if( string =~ /^(.+?) :.*help.*/ )
					addwhois($1, "ircophelp", 1)
				else
					rawunknown( "IRCOP Help? ", code, string )
				end
			elsif(code==310) #IRC OP Privs
				if( string =~ /^(.+?) :(.+)/ )
					addwhois($1, "ircop", 1)
					addwhois($1, "ircopprivs", $2)
				else
					rawunknown( "IRCOP Privs? ", code, string )
				end
			elsif(code==401) #No Nick Available
				if( string =~ /^(.+?) .+/ )
					addwhois($1,"nonick",1)
				else
					rawunknown( "No Nick Available ", code, string )
				end
			elsif(code==318) #End of whois... Send Data
				if( string =~ /^(.+?) .+/ )
					if (@whois[$1.downcase]["nonick"]!=1)
						@status.plugins.each_key do |key|
							if( @status.getplugin( key ).respond_to?( "whois" ) )
								@status.getplugin( key ).whois( @whois[$1.downcase] )
								@whois.delete($1.downcase)
							end
						end
					end
				else#Invalid REGEXP String
					rawunknown( "End of Whois ", code, string )
				end
			end#Whois Elsif

		#Message of the day
		elsif ([372,375,376].include?(code))
			if(code==372)
				if( string =~ /^\:(.+)/)
					@status.motd( $1 )
				end
			elsif(code==375)
				#if( string =~ /^\:(.+?) .+/ ) #Server could be grabbed from this line too...
					#server = $1
					@status.motdclear
				#end
			elsif(code==376)
				if( string =~ /^\:.+/ )
					@status.motd( "#EOMOTD#" )
				end
			else
				rawunknown( "MOTD ", code, string )
			end
		elsif(code==421)
			if( string =~ /^(.+?) :.+/ )
				@output.bad( "Unknown Command: #{$1}\n" )
			end
		else
			rawunknown( "", code, string )
		end
    end
	
	def mode( nick, user, host, chan, modes, nicks )
		i = modes.size - 1
		nicks = nicks.split( ' ' )
		while i  >= 1
			@status.plugins.each_key do |key|
				if( @status.getplugin( key ).respond_to?( "modes" ) )
					@status.getplugin( key ).modes( nick, user, host, chan, "#{modes[0]}#{modes[i]}", nicks[i-1] )
				end
			end
			i -= 1
		end
    end

    # Function for unknow messages
    def misc( unknown )
        # Passing on the signal for module autoloading
        if( unknown == "autoload" )
            tmp = Commands.new( @status, @config, @output, @irc, @timer, 1 )
            tmp.autoload
            tmp = nil
        end
    end

    # Function to sanitize user input
    def sanitize( input, downcase = 0 )
        input.gsub!( /[^a-zA-Z0-9 -]/, "" )
        if( downcase == 1 )
            input.downcase!
        end
    end
	def addwhois( nick, id, value )
		if(!@whois[nick.downcase])
			@whois[nick.downcase] = Hash.new(0)
			@whois[nick.downcase]["nick"] = nick
		end
		@whois[nick.downcase][id.downcase] = value
	end
	def rawunknown( name, code, string )
		#@output.bad( "Unknown RAW response [#{name}(#{code})]: #{string}\n" )
		@status.plugins.each_key do |key|
            if( @status.getplugin( key ).respond_to?( "raw" ) )
                @status.getplugin( key ).raw( code, string )
            end
        end
	end
end