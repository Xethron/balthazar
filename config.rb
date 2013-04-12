#!/usr/bin/env ruby

# Class used for initial bot configuration
# Modify the following variables to your liking
class Configuration
	def initialize( status, output )
		@nick		= "nanobot4"				# Bot nickname
		@user		= "nanobot"					# IRC username
		@pass		= ""						# NickServ password
		@version	= "Nanobot 4 beta 2"		# Version

		@command	= '\!'						# Character prefix for commands (escape special chars)

		@server		= "irc.insomnia247.nl"		# IPv4 address
		@server6	= "irc6.insomnia247.nl"		# IPv6 address
		@port		= 6667						# Normal port
		@sslport	= 6697						# SSL port

		@channels	= [ "#bot", "#test" ]
												# Autojoin channel list

		@opers		= [ "insomnia247.nl" ]
												# Opers list

		@data		= "data"					# Data directory
		@plugins	= "plugins"					# Plugin directory
		@autoload	= [ "core", "ddg", "help", "identified", "login", "seen", "shells", "toolbox", "translate", "twitter" ]
												# Plugin autoload list

		@antiflood	= true						# Attempt to mitigate people flooding bot with command
		@floodtime	= 5							# Command spread that triggers flood protect (seconds)

		@throttle	= true						# Throttle output to avoid flooding from the bot

		@autorejoin	= true						# Rejoin on kick
		@rejointime	= 3							# Time to wait before rejoin (seconds)

		@pingwait	= false						# Wait for server's first PING
		@conn_time	= 20						# Connect timeout
		@timeout	= 300						# IRC timeout

		@use_thread	= true						# Prefer threading
		@use_ipv6	= false						# Prefer IPv6
		@use_ssl	= true						# Prefer SSL
		@verif_ssl	= false						# Verify SSL certificate
		@rootcert	= "/etc/ssl/certs/ca-certificates.crt"
												# Path to openssl root certs (Needed if verify_ssl is enabled)

		@threadfb	= true						# Allow fallback to sequential processing when threads aren't available
		@sslfback	= false						# Allow fallback to insecure connect when OpenSSL library isn't available

		@status		= status					# System object, do not modify
		@output		= output					# System object, do not modify
	end

	# Get/set methods
	def nick( nick = "" )
		if( nick != "" )
			@nick = nick
		end
		return @nick
	end

	def pass( pass = "" )
		if( pass != "" )
			@pass = pass
		end
		return @pass
	end

	def user
		return @user
	end

	def pass
		@pass
	end

	def version
		return @version
	end

	def command( command = '' )
		if( command != '' )
			@command = command
		end
		return @command
	end

	def server
		if( @use_ipv6 )
			return @server6
		else
			return @server
		end
	end

	def port
		if( @use_ssl && @status.ssl )
			return @sslport
		elsif( @use_ssl && @status.ssl && @sslfback )
			@output.bad( "Warning: SSL is not available, insecure connection!\n" )
			return @port
		elsif( @use_ssl && @status.ssl && !@sslfback )
			@output.info( "\nSSL is not available, and fallback is disabled.\n" )
			Process.exit
		else
			return @port
		end
	end

	def ssl( ssl = "" )
		if( ssl != "" )
			@use_ssl = ssl
		end
		return @use_ssl
	end

	def verifyssl( ssl = "" )
		if( ssl != "" )
			@verif_ssl = ssl
		end
		return @verif_ssl
	end

	def rootcert
		return @rootcert
	end

	def ipv6( ipv6 = "" )
		if( ipv6 != "" )
			@use_ipv6 = ipv6
		end
		return @use_ipv6
	end

	def threads( threads = "" )
		if( threads != "" )
			@use_thread = threads
		end
		return @use_thread
	end

	def threadingfallback
		return @threadfb
	end

	def connecttimeout
		return @conn_time
	end

	def pingtimeout
		return @timeout
	end

	def antiflood ( antiflood = "" )
		if( antiflood != "" )
			@antiflood = antiflood
		end
		return @antiflood
	end

	def floodtime ( floodtime = "" )
		if( floodtime != "" )
			@floodtime = floodtime
		end
		return @floodtime
	end

	def throttleoutput ( throttle = "" )
		if( throttle != "" )
			@throttle = throttle
		end

		if( RUBY_VERSION =~ /^1\.8/ )
			return false
		else
			return @throttle
		end
	end

	def rejoin( rejoin = "" )
		if( rejoin != "" )
			@autorejoin = rejoin
		end
		return @autorejoin
	end

	def rejointime( rejointime = "" )
		if( rejointime != "" )
			@rejointime = rejointime
		end
		return @rejointime
	end

	def waitforping( wait = "" )
		if( wait != "" )
			@pingwait = wait
		end
		return @pingwait
	end

	def opers( opers = "" )
		if( opers != "" )
			@opers = opers
		end
		return @opers
	end

	def channels( channels = "" )
		if( channels != "" )
			@channels = channels
		end
		return @channels
	end

	def autoload( autoload = "" )
		if( autoload != "" )
			@autoload = autoload
		end
		return @autoload
	end

	def datadir( data = "" )
		if( data != "" )
			@data = data
		end
		return @data
	end

	def plugindir( plugins = "" )
		if( plugins != "" )
			@plugins = plugins
		end
		return @plugins
	end

	# Check for authorized users
	def auth( host, console )
		admin = 0

		if( console ) # No auth needed for console
			admin = 1
		else
			@opers.each do |adminhost|
				if( adminhost == host )
					admin = 1
				end				
			end
		end

		return( admin == 1 )
	end

	# Function to print out current configuration
	def show
		if( @status.showconfig )
			@output.info( "\nConfiguration:\n" )

			# General bot info
			@output.info( "\tBot info:\n" )
			@output.std( "\tNickname:\t\t" + @nick + "\n" )
			@output.std( "\tUsername:\t\t" + @user + "\n" )
			@output.std( "\tNickServ password:\t" + @pass + "\n" )
			@output.std( "\tVersion:\t\t" + @version + "\n" )
			@output.std( "\tCommand prefix:\t\t" + @command + "\n" )

			# Server info
			@output.info( "\n\tServer info:\n" )
			@output.std( "\tServer (IPv4):\t\t" + @server + "\n" )
			@output.std( "\tServer (IPv6):\t\t" + @server6 + "\n" )
			@output.std( "\tPrefer IPv6:\t\t" + yn(@use_ipv6) + "\n" )
			@output.std( "\tPort:\t\t\t" + @port.to_s + "\n" )
			@output.std( "\tSSL port:\t\t" + @sslport.to_s + "\n" )
			@output.std( "\tSSL Available:\t\t" + yn(@status.ssl) + "\n" )
			@output.std( "\tVerify SSL cert:\t" + yn(@verif_ssl) + "\n" )
			@output.std( "\tPath to root cert:\t" + @rootcert + "\n" )
			@output.std( "\tPrefer SSL:\t\t" + yn(@use_ssl) + "\n" )
			@output.std( "\tFallback if no SSL:\t" + yn(@sslfback) + "\n" )
			@output.std( "\tConnect timeout:\t" + @conn_time.to_s + " seconds\n" )
			@output.std( "\tIRC timeout:\t\t" + @timeout.to_s + " seconds\n" )
			@output.std( "\tWait for first PING:\t" + yn(@pingwait) + "\n" )

			# Channel autojoin
			@output.info( "\n\tAuto join channels:\n" )
			if( @channels[0] == nil )
				@output.std( "\t\t\t\tNone set.\n" )
			end
			@channels.each do |chan|
				@output.std( "\t\t\t\t" + chan + "\n" )
			end

			# Bot admins
			@output.info( "\n\tBot admin hosts:\n" )
			if( @opers[0] == nil )
				@output.std( "\t\t\t\tNone set.\n" )
			end
			@opers.each do |host|
				@output.std( "\t\t\t\t" + host + "\n" )
			end

			# Directory settings
			@output.info( "\n\tDirectories:\n" )
			@output.std( "\tBot data storage:\t" + @data + "\n" )
			@output.std( "\tPlugin directory:\t" + @plugins + "\n" )

			# Autoload plugins
			@output.info( "\n\tAuto load plugins:\n" )
			if( @autoload[0] == nil )
				@output.std( "\t\t\t\tNone set.\n" )
			end
			@autoload.each do |plugin|
				@output.std( "\t\t\t\t" + plugin + "\n" )
			end

			# Kick settings
			@output.info( "\n\tKick settings:\n" )
			@output.std( "\tRejoin after kick:\t" + yn(@autorejoin) + "\n" )
			@output.std( "\tWait before rejoin:\t" + @rejointime.to_s + " seconds\n" )

			# Threading settings
			@output.info( "\n\tThreading settings:\n" )
			@output.std( "\tThreading available:\t" + yn(@status.threads) + "\n" )
			@output.std( "\tUse threading:\t\t" + yn(@use_thread) + "\n" )
			@output.std( "\tAllow thread fallback:\t" + yn(@threadfb) + "\n" )

			# Antiflood
			@output.info( "\n\tAnti flood settings:\n" )
			@output.std( "\tFlood protect:\t\t" + yn(@antiflood) + "\n" )
			@output.std( "\tTime between triggers:\t" + @floodtime.to_s + " seconds\n" )

			# Output settings
			@output.info( "\n\tOutput settings:\n" )
			@output.std( "\tShow output:\t\tYes\n" )
			@output.std( "\tUse colours:\t\t" + yn(@status.colour) + "\n" )
			@output.std( "\tShow debug output:\t" + @status.debug.to_s + "\n" )
			@output.std( "\tDebug level:\t\t" )
			if( @status.debug == 0 )
				@output.std( "None\n" )
			elsif( @status.debug == 1 )
				@output.std( "Normal\n" )
			elsif( @status.debug == 2 )
				@output.std( "Extra\n" )
			else
				@output.std( "Extra + IRC threads\n" )
			end

			Process.exit
		end
	end

	# Support functions for config printing
	def yn( var )
		if( var )
			return "Yes"
		else
			return "No"
		end
	end
end
