#!/usr/bin/env ruby

# Class to delay sending messages to IRC
class Timer
	def initialize( status, config, output, irc )
		@status		= status
		@config		= config
		@output		= output
		@irc		= irc
	end

	# Add action to be evaluated
	def action( timeout, action )
		@output.debug( "Set action '" + action + "' to be executed in " + timeout.to_s + " seconds.\n" )

		if( @config.threads && @status.threads )
			Thread.new{ sleep( timeout ); eval( action ) }
		else
			@output.debug( "Not executing, threading disabled.\n" )
		end
	end
end
