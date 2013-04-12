#!/usr/bin/env ruby

# Input sanitation is done by wrapper.

# Calling actions from the DB
class User
	
	# This method is called when the plugin is first loaded
	def initialize( status, config, output, irc, timer )
		@status		= status
		@config		= config
		@output		= output
		@irc		= irc
		@timer		= timer
	end
	
	# Generic function that can be called by any user
	def getwhois( nick, user, host, from, msg, arguments, con )
		#@irc.notice( nick, "Loading Whois..." )
		mywhois = @whois.get( arguments )
		@irc.notice( nick, "#{mywhois}" )
	end
	
	def getmotd( nick, user, host, from, msg, arguments, con )
		motd = @status.motd
		i=0
		while ((motd[i] != "#EOMOTD#")&&(motd[i]!= nil))
			@irc.notice( nick, motd[i] )
			i += 1
			sleep 1
		end
	end
	
	def botinfo( nick, user, host, from, msg, arguments, con )
		@irc.notice( nick, @status.nick )
		@irc.notice( nick, @status.host )
		@irc.notice( nick, @status.server )
		@irc.notice( nick, @status.user )
	end
end