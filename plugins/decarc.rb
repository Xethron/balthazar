#!/usr/bin/env ruby

# This plugin decodes text from what we called in #Arcanea, Arcanian.

# Input sanitation is done by wrapper.

# Calling actions from the DB
class Decarc
	
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
		string = arguments
		if( from==@status.nick )
			words = string.split( /[^a-zA-Z0-9']/ )
			words.each do |word|
				len = word.length
				halve = len/2
				neword = ""
				i=1
				j=0
				while j < len
					if i >= len
						i=0
					end
					neword += word[i]
					i += 2
					j += 1
				end
				string = string.sub( word, word.each_char.zip(neword.downcase.each_char).map{|x,y| x.match(/[A-Z]/) ? y.upcase : y}.join )
			end
			@irc.message( nick, "#{string}" )
			@irc.message( "Xethron", "#{nick}: #{string}" )
		else
			@irc.notice( nick, "This command can only be used in PM" )
		end
	end
end
