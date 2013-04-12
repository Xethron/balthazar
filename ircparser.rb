#!/usr/bin/env ruby

require './ircparser_suroutines.rb'

# Class to parse IRC input
class IRCParser
	def initialize( status, config, output, irc, timer )
		@status		= status
		@config		= config
		@output		= output
		@irc		= irc
		@timer		= timer

		@sub		= IRCSubs.new( status, config, output, irc, timer )
	end

	# Start parser
	def start
		@irc.sendinit

		if( !@config.waitforping && !@status.login )
			@irc.login
			autoload
			@status.login( 1 )
		end

		# Main IRC parser loop
		begin
			while true

				# Set IRC timeout
				Timeout::timeout( @config.pingtimeout ) do
					line = @irc.socket.gets
					if( @status.threads && @config.threads )
						spawn_parser( line.chomp )
					else
						parser( line.chomp )
					end
				end
			end
		rescue Timeout::Error
			@output.debug( "IRC timeout, trying to reconnect.\n" )
			@irc.disconnect
		rescue IOError
			@output.debug( "Socket was closed.\n" )
		rescue Exception => e
			@output.debug( "Socket error: " + e.to_s + "\n" )
		end
	end

	# Meta function for starting threads
	def spawn_parser( line )

		# Join threads and print results if at the highest debug level
		if(@status.debug == 3)
			puts Thread.new { parser( line ) }.join
		else
			Thread.new { parser( line )	}
		end
	end

	# Main parser subroutine
	def parser( line )
		@output.debug_extra( "==> " + line + "\n" )

		# PING
		if( line =~ /^PING \:(.+)/ )
			@output.debug( "Received ping\n" )
			@irc.pong( $1 )

			if( @config.waitforping && !@status.login )
				@irc.login
				autoload
				@status.login( 1 )
			end

		# KICK
		elsif( line =~ /^\:(.+?)!(.+?)@(.+?) KICK (.+?) (.+?) \:(.+)/ )
			@output.debug( "Received kick\n" )
			@sub.kick( $1, $2, $3, $4, $5, $6 )

		# NOTICE
		elsif( line =~ /^\:(.+?)!(.+?)@(.+?) NOTICE (.+?) \:(.+)/ )
			@output.debug( "Received notice\n" )
			@sub.notice( $1, $2, $3, $4, $5 )

		# JOIN
		elsif( line =~ /^\:(.+?)!(.+?)@(.+?) JOIN \:?(.+)/ )
			@output.debug( "Received join\n" )
			@sub.join( $1, $2, $3, $4 )

		# PART
		elsif( line =~ /^\:(.+?)!(.+?)@(.+?) PART (.+)/ )
			@output.debug( "Received part\n" )
			@sub.part( $1, $2, $3, $4 )

		# QUIT
		elsif( line =~ /^\:(.+?)!(.+?)@(.+?) QUIT \:(.+)/ )
			@output.debug( "Received quit\n" )
			@sub.quit( $1, $2, $3, $4 )

		# PRIVMSG
		elsif( line =~ /^\:(.+?)!(.+?)@(.+?) PRIVMSG (.+?) \:(.+)/ )
			@output.debug( "Received message\n" )
			@sub.privmsg( $1, $2, $3, $4, $5 )

		# Other stuff
		else
			@sub.misc( line )
		end
	end
	
	# Function to start module autoloading
	def autoload
		if( @status.threads && @config.threads )
			spawn_parser( "autoload" )
		else
			parser( "autoload" )
		end
	end
end
		
