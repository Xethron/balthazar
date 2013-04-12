#!/usr/bin/env ruby

# Plugin that handles all the core functionality for the bot
class Core
	def initialize( status, config, output, irc, timer )
		@status		= status
		@config		= config
		@output		= output
		@irc		= irc
		@timer		= timer
	end

	# Messaging commands
	def message( nick, user, host, from, msg, arguments, con )
		if( @config.auth( host, con ) )
			if( !arguments.nil? && !arguments.empty? )
				to, message = arguments.split( ' ', 2 )
			end
	
			if( !to.nil? && !to.empty? && !message.nil? && !message.empty? )
				@irc.message( to, message )
			else
				if( con )
					@output.cinfo( "Usage: message send_to message to send" )
				else
					@irc.notice( nick, "Usage: " + @config.command + "message send_to message to send" )
				end
			end
		end
	end

	def raw( nick, user, host, from, msg, arguments, con )
		if( @config.auth( host, con ) )
			if( !arguments.nil? && !arguments.empty? )
				@irc.raw( arguments )
			else
				if( con )
					@output.cinfo( "Usage: raw line to send to IRC server" )
				else
					@irc.notice( nick, "Usage: " + @config.command + "raw line to send to IRC server" )
				end
			end
		end
	end

	def action( nick, user, host, from, msg, arguments, con )
		if( @config.auth( host, con ) )
			if( !arguments.nil? && !arguments.empty? )
				to, action = arguments.split( ' ', 2 )
			end

			if( !to.nil? && !to.empty? && !action.nil? && !action.empty? )
				@irc.action( to, action )
			else
				if( con )
					@output.cinfo( "Usage: action send_to message to send" )
				else
					@irc.notice( nick, "Usage: " + @config.command + "action send_to message to send" )
				end
			end
		end
	end

	def notice( nick, user, host, from, msg, arguments, con )
		if( @config.auth( host, con ) )
			if( !arguments.nil? && !arguments.empty? )
				to, message = arguments.split( ' ', 2 )
			end

			if( !to.nil? && !message.nil? && !to.empty? && !message.empty? )
				@irc.notice( to, message )
			else
				if( con )
					@output.cinfo( "Usage: notice send_to message to send" )
				else
					@irc.notice( nick, "Usage: " + @config.command + "notice send_to message to send" )
				end
			end
		end
	end

	# Join/part commands
	def join( nick, user, host, from, msg, chan, con )
		if( @config.auth( host, con ) )
			if( !chan.nil? && !chan.empty? )
				@irc.join( chan )
			else
				if( con )
					@output.cinfo( "Usage: join #channel", true )
				else
					@irc.notice( nick, "Usage: " + @config.command + "join #channel" )
				end
			end
		end
	end

	def part( nick, user, host, from, msg, chan, con )
		if( @config.auth( host, con ) )
			if( !chan.nil? && !chan.empty? )
				@irc.part( chan )
			else
				if( con )
					@output.cinfo( "Usage: part #channel", true )
				else
					@irc.notice( nick, "Usage: " + @config.command + "part #channel" )
				end
			end
		end
	end

	# Topic command
	def topic( nick, user, host, from, msg, arguments, con )
		if( @config.auth( host, con ) )
			if( !arguments.nil? && !arguments.empty? )
				chan, topic = arguments.split( ' ', 2 )
				if( chan !~ /^#/ && !con )
					topic = arguments
					chan = from
				end
				if( !chan.nil? && !chan.empty? )
					@irc.topic( chan, topic )
				end
			else
				if( con )
					@output.cinfo( "Usage: topic #channel new topic" )
				else
					@irc.notice( nick, "Usage: " + @config.command + "topic #channel new topic" )
				end
			end
		end
	end

	# Mode command
	def mode( nick, user, host, from, msg, arguments, con )
		if( @config.auth( host, con ) )
			if( arguments == nil )
				arguments = ""
			end

			if( arguments.split.size >= 2 )
				if( arguments.split.size >= 3 )
					chan, mode, name = arguments.split( ' ', 3 )
				elsif( arguments.split.size == 2 )
					chan, mode = arguments.split( ' ', 2 )
					name = ""
				end
				@irc.mode( chan, mode, name )
			else
				if( con )
					@output.cinfo( "Usage: mode #channel +/-mode nick", true )
				else
					@irc.notice( nick, "Usage: " + @config.command + "Usage: mode #channel +/-mode nick" )
				end
			end
		end
	end

	# Oper commands
	def op( nick, user, host, from, msg, arguments, con )
		if( @config.auth( host, con ) )
			if( arguments == nil )
				arguments = ""
			end

			if( ( con && arguments.split.size == 2 ) || ( !con ) )
				if( con || arguments.split.size == 2 )
					chan, name = arguments.split( ' ', 2 )
				elsif( arguments.split.size == 1 )
					chan = from
					name = arguments
				else
					chan = from
					name = nick
				end
				@irc.mode( chan, "+o", name, true )
			else
				if( con )
					@output.cinfo( "Usage: op #channel user" )
				else
					@irc.notice( nick, "Usage: " + @config.command + "op #channel user" )
				end
			end
		end
	end

	def deop( nick, user, host, from, msg, arguments, con )
		if( @config.auth( host, con ) )
			if( arguments == nil )
				arguments = ""
			end

			if( ( con && arguments.split.size == 2 ) || ( !con ) )
				if( con || arguments.split.size == 2 )
					chan, name = arguments.split( ' ', 2 )
				elsif( arguments.split.size == 1 )
					chan = from
					name = arguments
				else
					chan = from
					name = nick
				end
				@irc.mode( chan, "-o", name, true )
			else
				if( con )
					@output.cinfo( "Usage: deop #channel user" )
				else
					@irc.notice( nick, "Usage: " + @config.command + "deop #channel user" )
				end
			end
		end
	end

	# Half-oper commands
	def hop( nick, user, host, from, msg, arguments, con )
		if( @config.auth( host, con ) )
			if( arguments == nil )
				arguments = ""
			end

			if( ( con && arguments.split.size == 2 ) || ( !con ) )
				if( con || arguments.split.size == 2 )
					chan, name = arguments.split( ' ', 2 )
				elsif( arguments.split.size == 1 )
					chan = from
					name = arguments
				else
					chan = from
					name = nick
				end
				@irc.mode( chan, "+h", name, true )
			else
				if( con )
					@output.cinfo( "Usage: hop #channel user" )
				else
					@irc.notice( nick, "Usage: " + @config.command + "hop #channel user" )
				end
			end
		end
	end

	def dehop( nick, user, host, from, msg, arguments, con )
		if( @config.auth( host, con ) )
			if( arguments == nil )
				arguments = ""
			end

			if( ( con && arguments.split.size == 2 ) || ( !con ) )
				if( con || arguments.split.size == 2 )
					chan, name = arguments.split( ' ', 2 )
				elsif( arguments.split.size == 1 )
					chan = from
					name = arguments
				else
					chan = from
					name = nick
				end
				@irc.mode( chan, "-h", name, true )
			else
				if( con )
					@output.cinfo( "Usage: dehop #channel user" )
				else
					@irc.notice( nick, "Usage: " + @config.command + "dehop #channel user" )
				end
			end
		end
	end

	# Voice commands
	def voice( nick, user, host, from, msg, arguments, con )
		if( @config.auth( host, con ) )
			if( arguments == nil )
				arguments = ""
			end

			if( ( con && arguments.split.size == 2 ) || ( !con ) )
				if( con || arguments.split.size == 2 )
					chan, name = arguments.split( ' ', 2 )
				elsif( arguments.split.size == 1 )
					chan = from
					name = arguments
				else
					chan = from
					name = nick
				end
				@irc.mode( chan, "+v", name, true )
			else
				if( con )
					@output.cinfo( "Usage: voice #channel user" )
				else
					@irc.notice( nick, "Usage: " + @config.command + "voice #channel user" )
				end
			end
		end
	end

	def devoice( nick, user, host, from, msg, arguments, con )
		if( @config.auth( host, con ) )
			if( arguments == nil )
				arguments = ""
			end

			if( ( con && arguments.split.size == 2 ) || ( !con ) )
				if( con || arguments.split.size == 2 )
					chan, name = arguments.split( ' ', 2 )
				elsif( arguments.split.size == 1 )
					chan = from
					name = arguments
				else
					chan = from
					name = nick
				end
				@irc.mode( chan, "-v", name, true )
			else
				if( con )
					@output.cinfo( "Usage: devoice #channel user" )
				else
					@irc.notice( nick, "Usage: " + @config.command + "devoice #channel user" )
				end
			end
		end
	end

	# Kick commands
	def kick( nick, user, host, from, msg, arguments, con )
		if( @config.auth( host, con ) )
			if( !arguments.nil? && !arguments.empty? )
				if( arguments =~ /^#/ )
					chan, name, reason = arguments.split( ' ', 3 )
				else
					name, reason = arguments.split( ' ', 2 )
					chan = from
				end

				if( reason.nil? || reason.empty?)
					reason = "Requested by " + nick + "."
				end

				@irc.kick( chan, name, reason, true )
			else
				if( con )
					@output.cinfo( "Usage: kick #channel nick" )
				else
					@irc.notice( nick, "Usage: " + @config.command + "kick #channel nick" )
				end
			end
		end
	end

	# Banning commands
	def ban( nick, user, host, from, msg, arguments, con )
		if( @config.auth( host, con ) )
			if( !arguments.nil? && !arguments.empty? )
				chan, host = arguments.split( ' ', 2 )
			end

			if( host.nil? || host.empty? ) # Overload parameters when no channel is given
				host	= chan
				chan	= from
			end

			@irc.mode( chan, "+b", host, true )
		else
			if( con )
				@output.cinfo( "Usage: ban #channel host" )
			else
				@irc.notice( nick, "Usage: " + @config.command + "ban #channel host" )
			end
		end
	end

	def unban( nick, user, host, from, msg, arguments, con )
		if( @config.auth( host, con ) )
			if( !arguments.nil? && !arguments.empty? )
				chan, host = arguments.split( ' ', 2 )
			end

			if( host.nil? || host.empty? ) # Overload parameters when no channel is given
				host	= chan
				chan	= from
			end

			@irc.mode( chan, "-b", host, true )
		else
			if( con )
				@output.cinfo( "Usage: unban #channel host" )
			else
				@irc.notice( nick, "Usage: " + @config.command + "unban #channel host" )
			end
		end
	end

	def timeban( nick, user, host, from, msg, arguments, con )
		if( @config.auth( host, con ) )
			if( @config.threads && @status.threads )
				if( !arguments.nil? && !arguments.empty? )
					chan, host, timeout = arguments.split( ' ', 3 )
				end

				if( !chan.nil? && !chan.empty? && !host.nil? && !host.empty? && ( !con || ( !timeout.nil? && !timeout.empty? ) ) )
					if( timeout.nil? || timeout.empty? ) # Overload parameters when no channel is given
						timeout	= host
						host	= chan
						chan	= from
					end

					@irc.mode( chan, "+b", host, true )
					@timer.action( timeout.to_i, "@irc.mode( \"#{chan}\", \"-b\", \"#{host}\", true )" )

					if( con )
						@output.cinfo( "Unban set for " + timeout.to_s + " seconds from now." )
						@irc.message( chan, "Unban set for " + timeout.to_s + " seconds from now." )
					else
						@irc.message( from, "Unban set for " + timeout.to_s + " seconds from now." )
					end
				else
					if( con )
						@output.cinfo( "Usage: timeban #channel host seconds" )
					else
						@irc.notice( nick, "Usage: " + @config.command + "timeban #channel host seconds" )
					end
				end
			else
				@irc.notice( nick, "Timeban not availble when threading is disabled." )
			end
		end
	end

	# Echo version to the user
	def version( nick, user, host, from, msg, arguments, con )
		output = "Running: " + @config.version + " on Ruby " + RUBY_VERSION
		if( con )
			@output.cinfo( output )
		else
			@irc.notice( nick, output )
		end
		output = nil
		uptime( nick, user, host, from, msg, arguments, con )
	end

	# Echo uptime to the user
	def uptime( nick, user, host, from, msg, arguments, con )
		uptime = "Uptime: " + @status.uptime + "."
		if( con )
			@output.cinfo( uptime )
		else
			@irc.notice( nick, uptime )
		end
		uptime = nil
	end

	def nick( nick, user, host, from, msg, arguments, con )
		if( @config.auth( host, con ) )
			if( !arguments.nil? && !arguments.empty? )
				@config.nick( arguments )
				@irc.nick( arguments )
			end
		end
	end
end
