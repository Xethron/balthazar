#!/usr/bin/env ruby

# Idea to capture Whois

class Whois
	
	def initialize( status, config, output, irc, timer )
		@status		= status
		@config		= config
		@output		= output
		@irc		= irc
		@timer		= timer
		@reqs		= Array.new
		@queue		= Queue.new
	end
	
	#Function gets called by another class who wants to get user whois info
	def get( nick )
		@reqs.concat ( [nick.downcase] )
		@irc.raw( "whois #{nick}" )
		hash = @queue.deq
		while hash["nick"].downcase != nick.downcase
			hash = @queue.deq
		end
		return hash
	end
	
	#Hash Table gets sent containing all the user info after code 138 was recieved by the parser
	def whois( hash )
		if @reqs.include?(hash["nick"].downcase)
			@queue.enq hash
			@reqs.delete_at @reqs.index(hash["nick"].downcase)
		end
	end
end
