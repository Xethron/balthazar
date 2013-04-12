#!/usr/bin/env ruby

# Plugin that allows people to kick random users, at the price of also being kicked, and banned for n seconds
class Kamikaze

	# This method is called when the plugin is first loaded
	def initialize( status, config, output, irc, timer )
		@status		= status
		@config		= config
		@output		= output
		@irc		= irc
		@timer		= timer

		@bantime	= 120
	end

	# Default method
	def main( nick, user, host, from, msg, arguments, con )
		if( !arguments.nil? && !arguments.empty? )
			arguments.gsub!( / /, "" )
			if( arguments != @config.nick )
				# Kick target
				@irc.kick( from, arguments, nick + " really hates you." )
				
				# Ban issuer
				@irc.mode( from, "+b", host )

				# Kick issuer
				@irc.kick( from, nick, "See you in " + @bantime.to_s + " seconds." )

				# Set unban for issuer
				@timer.action( @bantime, "@irc.mode( \"#{from}\", \"-b\", \"#{host}\" )" )
			end
		else
			help( nick, user, host, from, msg, arguments, con )
		end
	end

	# Help method
	def help( nick, user, host, from, msg, arguments, con )
		help = [
			"This module provides the ability to kick other users, but at a terrible price!",
			"  kamikaze [user]            - Kick a user.",
			"  kamikaze help              - Provides this help."
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
end
