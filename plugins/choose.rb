#!/usr/bin/env ruby

# Simple Choose/8ball/lotto type script

# Input sanitation is done by wrapper.

# Calling actions from the DB
class Choose
	
	# This method is called when the plugin is first loaded
	def initialize( status, config, output, irc, timer )
		@status		= status
		@config		= config
		@output		= output
		@irc		= irc
		@timer		= timer
		@eightball		= ["Yes","No","Maybe","How should I know?","Computer says: Yes","Computer says: No!","Computer says: ERROR ID: 10-T"]
	end
	
	# Generic function that can be called by any user
	def main( nick, user, host, from, msg, arguments, con )
		if (arguments == "!lotto")
			#@irc.message( from, "Checking lotto numbers" )
			numbers = Array.new(49){|i| i+1 }
			lotto = Array.new(6)
			for i in 0..5
				lotto[i] = numbers.sample
				numbers.delete_at(i)
			end
			lotto.sort!
			choice = "I think the winning lotto numbers are: #{lotto[0]}, #{lotto[1]}, #{lotto[2]}, #{lotto[3]}, #{lotto[4]}, #{lotto[5]}"
		elsif (arguments =~ /^!8ball (.+?) /)
			choice = "#{@eightball.sample}"
		else
			choice = "I choose #{arguments.split( ' or ' ).sample}"
		end
		@irc.message( from, "#{nick}, #{choice}" )
	end
end
