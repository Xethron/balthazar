#!/usr/bin/env ruby

# Plugin with misc functions for #shells
class Shells

	# This method is called when the plugin is first loaded
	def initialize( status, config, output, irc, timer )
		@status		= status
		@config		= config
		@output		= output
		@irc		= irc
		@timer		= timer

		@chan		= "#shells"
	end

	# Main method
	def main( nick, user, host, from, msg, arguments, con )
		line = "Invalid input. Use the help function to check available commands."
		if( con )
			@output.c( line + "\n" )
		else
			@irc.notice( nick, line )
		end
	end

	# Method for parsing standard messages
	def messaged( nick, user, host, from, message )
		# Check for right channel
		if( from == @chan )
			# Check for exempted uses
			if( nick !~ /Cool_Fire|cFire|blueice|PowerWing|rundata|MatteWan/i )
				if( message =~ /(how|can|may).+(ha[ve,z,s]|get|request|invite).+(sh[e,3]ll)/i )
					@irc.message( @chan, "Hello #{nick}, please visit http://wiki.insomnia247.nl/wiki/Shells_FAQ#How_do_I_request_a_shell.3F for information on requesting shells.")
				elsif( message =~ /(how|can|may).+(ha[ve,z,s]|get|request|invite).+(code|invite)/i )
					@irc.message( @chan, "Hello #{nick}, please visit http://wiki.insomnia247.nl/wiki/Shells_FAQ#How_do_I_get_an_invite.3F for information on getting an invite." )
				end
			end
		end
	end

	# Method that receives a notification when a user joins
	def joined( nick, user, host, channel )
		if( channel == @chan )
			@irc.notice( nick, "Hello #{nick}, welcome to #shells for Insomnia 24/7 shell support.");
			@irc.notice( nick, "If no one is here to help you, please stick around or email your questions to cool_fire_666\@hotmail.com.");

			voice = Net::HTTP.get( 'www.insomnia247.nl', '/users.php?user=' + nick )
			if( voice == "YES" )
				@irc.mode( channel, "+v" , nick, true )
			end
		end
	end

	# Show information about open ports
	def port( nick, user, host, from, msg, arguments, con )
		ports( nick, user, host, from, msg, arguments, con )
	end
	def ports( nick, user, host, from, msg, arguments, con )
		info = [
			"Our shells have ports 5000 to 5500 open for incoming connections.",
			"The port command can be used from your shell to determime which ports are available to you.",
			"Use  port -a  to see which ports are still available.",
			"Use  port -s portnumber  to see if a specific port you would like to use is still available.",
			"For more information, go here: http://wiki.insomnia247.nl/wiki/Shells_ports"
		]
		printhelp( from, con, info )
	end

	# Show information about users websites.
	def website( nick, user, host, from, msg, arguments, con )
		websites( nick, user, host, from, msg, arguments, con )
	end
	def websites( nick, user, host, from, msg, arguments, con )
		info = [
			"Our shells allow you to host a small website on your shell.",
			"You need to put your websites files in the public_html folder on your shell.",
			"You can now view your website at yourname.insomnia247.nl.",
			"For more information, go here: http://wiki.insomnia247.nl/wiki/Shells_websites"
		]
		printhelp( from, con, info )
	end

	# Show information about Google Go.
	def go( nick, user, host, from, msg, arguments, con )
		info = [
			"On our shells you can use the Google Go programming language.",
			"If you want to use this feature, use the enable_go command from your shell, this will set up your environment correctly.",
			"For further help on using Google Go visit: http://golang.org/doc/go_tutorial.html"
		]
		printhelp( from, con, info )
	end
	
	# Show information about backups.
	def backup( nick, user, host, from, msg, arguments, con )
		backups( nick, user, host, from, msg, arguments, con )
	end
	def backups( nick, user, host, from, msg, arguments, con )
		info = [
			"You can use the backup command on your shell to backup or restore files from or to our off-site backup.",
			"Full backups of the home directories are made every Monday, Wednesday and Friday at 5:40am local time.",
			"You need to give your full path to the backup application, so if you want to restore a file called 'code.c' in your home directory:",
			"backup --restore /home/username/code.c",
			"Use 'backup --help' to get more information on usage.",
			"For more info, go here: http://wiki.insomnia247.nl/wiki/Shells_ports"
		]
		printhelp( from, con, info )
	end

	# Show information about ZNC.
	def znc( nick, user, host, from, msg, arguments, con )
		info = [
			"You can find a guide to setting up ZNC for your shell here: http://wiki.insomnia247.nl/wiki/Shells_ZNC"
		]
		printhelp( from, con, info )
	end
	
	# Function to send help about this plugin (Can also be called by the help plugin.)
	def help( nick, user, host, from, msg, arguments, con )
		help = [
			"This plugin provides several functions to support " + @chan + ".",
			"  shells ports           - Show information about open ports.",
			"  shells websites        - Show information about users websites.",
			"  shells go              - Show information about Google Go.",
			"  shells backups         - Show information about backups.",
			"  shells znc             - Show information about ZNC.",
			"  shells uptime          - Show uptime for shell hosts.",
			"  shells users           - Show user count for shell hosts.",
			"  shells online          - Show online user count for shell hosts.",
			"  shells month           - Show number of active users this month for shell hosts.",
			"  shells load            - Show load avarage for shell hosts",
			"  shells kernel          - Show kernel version for shell hosts."
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

	# Stats functions
	def uptime( nick, user, host, from, msg, arguments, con )
		getstat( from, "uptime" )
	end

	def users( nick, user, host, from, msg, arguments, con )
		getstat( from, "users" )
	end

	def online( nick, user, host, from, msg, arguments, con )
		getstat( from, "ousers" )
	end

	def month( nick, user, host, from, msg, arguments, con )
		getstat( from, "numusers" )
	end

	def load( nick, user, host, from, msg, arguments, con )
		getstat( from, "load" )
	end

	def kernel( nick, user, host, from, msg, arguments, con )
		getstat( from, "kernel" )
	end

	private

	# Function to grab statistics from shell hosts.
	def getstat( chan, stat )
		iline = Net::HTTP.get( 'www.insomnia247.nl', '/stats.php?get=' + stat )
		rline = Net::HTTP.get( 'rootedker.nl', '/stats.php?get=' + stat )
		#fline = Net::HTTP.get( 'coolfire.fastshells.co.uk', '/stats.php?get=' + stat )

		@irc.message( chan, "Insomnia 24/7: " + iline )
		@irc.message( chan, "Rootedker.nl:  " + rline )
		#@irc.message( chan, "Fastshells:    " + fline )
	end

	# Function to print arrays
	def printhelp( to, con, info )
		info.each do |line|
			if( con )
				@output.c( line + "\n" )
			else
				@irc.message( to, line )
			end
		end
	end
end
