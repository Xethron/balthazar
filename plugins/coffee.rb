#!/usr/bin/env ruby

# Simple script that makes a user coffee :D

# Input sanitation is done by wrapper.

# Calling actions from the DB
class Coffee
	
	# This method is called when the plugin is first loaded
	def initialize( status, config, output, irc, timer )
		@status		= status
		@config		= config
		@output		= output
		@irc		= irc
		@timer		= timer
	end
	
	# Generic function that can be called by any user
	def main( nick, user, host, from, msg, arguments, con )
		if( arguments.nil? || arguments.empty? )
			tonick = nick
		else
			tonick = arguments
		end
		@irc.action( from, "makes coffee for #{tonick}" )
	end
end
