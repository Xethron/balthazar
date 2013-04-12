#!/usr/bin/env ruby

# Class bot uses to store it's status
# Do not modify variables manually
class Status
	def initialize
		@output		= 1
		@colour		= 1
		@debug		= 0
		@login		= 0
		@threads	= 0
		@ssl		= 0
		@showconf	= 0
		@console	= 1
		@reconnect	= 1
		@plugins	= {}
		@startup	= Time.new
		
		#Server Vars
		@nick		= ""
		@user		= ""
		@host		= ""
		@server		= ""
		@motd		= Array.new
	end
	
	# Some basic server vars...
	def nick( nick = "" )
		if( nick != "" )
			@nick = nick
		end
		return @nick
	end
	
	def user( user = "" )
		if( user != "" )
			@user = user
		end
		return @user
	end
	
	def host( host = "" )
		if( host != "" )
			@host = host
		end
		return @host
	end
	
	def server( server = "" )
		if( server != "" )
			@server = server
		end
		return @server
	end
	
	def motd( motd = "" )
		if( motd != "" )
			@motd[@motd.size] = motd
			if( motd[@motd.size-1] == "#EOMOTD#" )
				return @motd
			else
				return ["No Valid MOTD"] #Returns in Array format
			end
		end
	end
	
	def motdclear
		@motd.clear
	end

	# Get/set functions
	def output( output = "" )
		if( output != "" )
			@output = output
		end
		return( @output == 1 )
	end

	def colour( colour = "" )
		if( colour != "" )
			@colour = colour
		end
		return( @colour == 1 )
	end

	def debug( debug = "" )
		if( debug != "" )
			@debug = debug
		end
		return @debug
	end

	def login( login = "" )
		if( login != "" )
			@login = login
		end
		return( @login == 1 )
	end

	def threads( threads = "" )
		if( threads != "" )
			@threads = threads
		end
		return( @threads == 1 )
	end

	def ssl( ssl = "" )
		if( ssl != "" )
			@ssl = ssl
		end
		return( @ssl == 1 )
	end

	def console( console = "" )
		if( console != "" )
			@console = console
		end
		return( @console == 1 )
	end

	def reconnect( reconnect = "" )
		if( reconnect != "" )
			@reconnect = reconnect
		end
		return( @reconnect == 1 )
	end

	def showconfig( show = "" )
		if( show != "" )
			@showconf = show
		end
		return( @showconf == 1 )
	end

	# Functions to deal with plugins
	def plugins( plugins = "" )
		if( plugins != "" )
			@plugins = plugins
		end
		return @plugins
	end

	def addplugin( name, plugin )
		@plugins[ name ] = plugin
	end

	def delplugin( name )
		@plugins[ name ] = nil
		@plugins.delete( name )
	end

	def checkplugin( name )
		return( @plugins.has_key?( name ) )
	end

	def getplugin( name )
		return( @plugins.fetch( name ) )
	end

	def startup
		return @startup
	end

	# Function to calculate uptime string
	def uptime( now = Time.now, start = @startup )
		output = ""
		diff = now - start

		weeks	= ( diff/604800 ).to_i
		days	= ( diff/86400 - ( weeks * 7 ) ).to_i
		hours	= ( diff/3600 - ( days * 24 + weeks * 168 ) ).to_i
		minutes = ( diff/60 - ( hours * 60 + days * 1440 + weeks * 10080 ) ).to_i
		seconds = ( diff - ( minutes * 60 + hours * 3600 + days * 86400 + weeks * 604800 ) ).to_i
		
		if( weeks > 0 )
			output = weeks.to_s + " week"
			if( weeks != 1 )
				output = output + "s"
			end
			output = output + ", "
		end

		if( days > 0 )
			output = output + days.to_s + " day"
			if( days != 1 )
				output = output + "s"
			end
			output = output + ", "
		end

		if( hours > 0 )
			output = output + hours.to_s + " hour"
			if( hours != 1 )
				output = output + "s"
			end
			output = output + ", "
		end

		if( minutes > 0 )
			output = output + minutes.to_s + " minute"
			if( minutes != 1 )
				output = output + "s"
			end
			output = output + " and "
		end

		output = output + seconds.to_s + " second"
		if( seconds != 1 )
			output = output + "s"
		end

		return output
	end
end
