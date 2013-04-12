#!/usr/bin/env ruby

# Plugin to do passworded login
class Login

	# This method is called when the plugin is first loaded
	def initialize( status, config, output, irc, timer )

		begin
			require 'rubygems'
			require 'bcrypt'
		rescue LoadError
			raise LoadError, "Cannot load bcrypt library. Make sure the bcrypt-ruby gem is installed."
		end

		@status		= status
		@config		= config
		@output		= output
		@irc		= irc
		@timer		= timer

		@password	= ""
		@filename	= "password.data"

		loadpass
	end

	# Default method, called when no argument is given (optional, but highly recomended)
	def main( nick, user, host, from, msg, arguments, con )
		returnval = ""

		# Check for empty pass
		if( !arguments.nil? && !arguments.empty? )

			# Check password
			if( @password == arguments )
				@config.opers( @config.opers.push( host) )
				returnval = "Login successful, added your host to admin list."
			else
				returnval = "Login unsuccessful, password did not match."
			end
		else
			help( nick, user, host, from, msg, arguments, con )
		end

		if( con )
			@output.c( returnval + "\n" )
		else
			@irc.notice( nick, returnval, true )
		end
	end

	# Function to set password
	def set( nick, user, host, from, msg, arguments, con )
		if( @config.auth( user, host, con ) )
			if( !arguments.nil? && !arguments.empty? )
				@password = BCrypt::Password.create arguments
				writepass
			end
		end
	end

	# Function to send help about this plugin (Can also be called by the help plugin.)
	def help( nick, user, host, from, msg, arguments, con )
		help = [
			"This plugin allows users to log in with a password when their hostmask is not in the oper list.",
			"  login [password]        - Login with password.",
			"  login set [password]    - Set new password."
		]

		# Print out help
		help.each do |line|
			if( con )
				@output.c( line + "\n" )
			else
				@irc.notice( nick, line )
			end
		end
	end

	private

	# Function to load marshaled password on startup
	def loadpass
		# Check if a password is stored on disk
		if File.exists?( @config.datadir + '/' + @filename )

			# Read password from file
        	File.open( @config.datadir + '/' + @filename ) do |file|
				@password = Marshal.load( file )
			end
		end
	end

	# Function to marshal out password to file
	def writepass
		File.open( @config.datadir + '/' + @filename, 'w' ) do |file|
			Marshal.dump( @password, file )
		end
	end
end
