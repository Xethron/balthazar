#!/usr/bin/env ruby

require './commands.rb'

# Class to handle console input
class Console
	def initialize( status, config, output, irc, timer )
		@status		= status
		@config		= config
		@output		= output
		@irc		= irc
		@timer		= timer

		@cmd		= Commands.new( status, config, output, irc, timer, 1 )
	end

	# Start up console
	def start
		@output.std( "Commandline input parsing ........ " )

		if( @config.threads && @status.threads )
			@output.good( "[OK]\n" )

			Thread.new{ parse }
		else
			@output.bad( "[NO]\n" )
			@output.debug( "Not parsing user input, threading disabled.\n" )
		end
	end

	# Parser function
	def parse
		@output.cspecial( @config.version + " console" )

		while true do
			print( @config.nick + "# " )
			STDOUT.flush
			@cmd.process( "", "", "", "", STDIN.gets.chomp )
		end
	end
end
