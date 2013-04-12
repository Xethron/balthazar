#!/usr/bin/env ruby

# Plugin to do autovoice in #ddg
class Ddg

	# This method is called when the plugin is first loaded
	def initialize( status, config, output, irc, timer )
		@status		= status
		@config		= config
		@output		= output
		@irc		= irc
		@timer		= timer

		@channel	= "#ddg"
	end
	
	# Method that receives a notification when a user joins (optional)
	def joined( nick, user, host, channel )
		if( channel == @channel )
			@irc.mode( channel, "+v" ,nick, true )
		end
	end
end
