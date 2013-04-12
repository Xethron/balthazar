#!/usr/bin/env ruby

# Class handle the sending of messages to IRC
class IRC
	def initialize( status, config, output, socket )
		@status		= status
		@config		= config
		@output		= output
		@socket		= socket

		if( usequeue )
			@high	= Queue.new
			@low	= Queue.new
			@proc	= Thread.new{ processqueues }
			@signal	= Queue.new
		end
	end

	# Method to determine the use of queues.
	def usequeue
		return( @status.threads && @config.threads && @config.throttleoutput )
	end

	# Function for queued sending thread
	def processqueues
		while true do
			line = nil
			@signal.pop
			if( !@high.empty? )
				# Process high priority
				line = @high.pop
				@output.debug_extra( "<==+ " + line + "\n")
			elsif( !@low.empty? )
				# Process low priority
				line = @low.pop
				@output.debug_extra( "<==- " + line + "\n")
			end

			# Send output
			if( !line.nil? )
				@socket.puts( line )
				sleep( 1 )
			end
		end
		
	end
	
	# Function to add stuff to queues ( Low priority unless specified otherwise. )
	def enqueue( line, high = false )
		if( high )
			@high.push( line )
		else
			@low.push( line )
		end

		# Tell the processing thread data is ready.
		@signal.push( "" )
	end
	
	# Get raw socket.
	def socket
		return @socket
	end

	# Send raw data to IRC
	def raw( line, high = false )
		if( usequeue )
			enqueue( line, high )
		else
			@output.debug_extra( "<== " + line + "\n")
			@socket.puts( line )
		end
	end

	# Send initial connect data
	def sendinit
		raw( "NICK " + @config.nick )
		raw( "USER " + @config.user + " 8 *  :" + @config.version )
	end

	# Send login info
	def login
		# Do nickserv login
		if( @config.pass != "" )
			message( "NickServ", "IDENTIFY " + @config.pass )
		end

		# Join channels
		@config.channels.each do |channel|
			join( channel )
		end
	end

	# Reply to PINGs
	def pong( line )
		raw( "PONG " + line, true )

		if( @config.waitforping && !@status.login )
			login
			@status.login( 1 )
		end
	end

	# Send standard message
	def message( to, message, high = false )
		raw( "PRIVMSG " + to + " :" + message, high )
	end

	# Send ACTION message
	def action( to, action, high = false )
		raw( "PRIVMSG " + to + " :ACTION " + action + "", high )
	end

	# Send notice
	def notice( to, message, high = false )
		raw( "NOTICE " + to + " :" + message, high )
	end

	# Change nickname
	def nick( nick, high = false )
		@config.nick( nick )
		raw( "NICK " + nick, high )
	end

	# Set topic
	def topic( channel, topic, high = false )
		raw( "TOPIC " + channel + " :" + topic, high )
	end

	# Join channel
	def join( channel, high = false )
		raw( "JOIN " + channel, high )
	end

	# Part channel
	def part( channel, high = false )
		raw( "PART " + channel, high )
	end

	# Kick user
	def kick( channel, user, reason, high = false )
		raw( "KICK " + channel + " " + user + " " + reason, high )
	end

	# Set modes
	def mode( channel, mode, subject, high = false )
		raw( "MODE " + channel + " " + mode + " " + subject, high )
	end

	# Quit IRC
	def quit( message, high = false )
		raw( "QUIT " + message, high )
		disconnect
	end

	# Disconnect socket
	def disconnect
		@status.login( 0 )
		@socket.close
	end
end
		
