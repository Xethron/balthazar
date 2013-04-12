#!/usr/bin/env ruby

# Plugin to keep track of when users were last seen.
class Seen

	# This method is called when the plugin is first loaded
	def initialize( status, config, output, irc, timer )
		@status		= status
		@config		= config
		@output		= output
		@irc		= irc
		@timer		= timer
		@filename	= "seen.data"

		# Storage timing settings
		@every		= 50	# Write to disk after every n actions
		@current	= 0		# Number of actions since last write

		# Declare empty hashtables
		@seen		= {}
		@time		= {}
		@seen2		= {}
		@time2		= {}

		@first		= Time.new

		# See if there is a database stored to disk we can load
		load_db
	end

	# Grab last seen
	def main( nick, user, host, from, msg, arguments, con )
		# Declare result string
		line = nil

		# Check if there is input
		if( !arguments.nil? && !arguments.empty? )
			arguments.gsub!( / /, "" )
			arguments.downcase!

			# Check for log data
			if( !@seen2[ arguments ].nil? )
				beforelast( nick, user, host, from, msg, arguments, con )
			end

			if( !@seen[ arguments ].nil? )
				last( nick, user, host, from, msg, arguments, con )
			else
				line = "No log for " + arguments + ". " + "Log goes back " + @status.uptime( Time.now, @first ) + "."
			end
		
		else
			line = "Please specify a nickname."
		end

		# Output error message if needed.
		if( !line.nil? )
			if( con )
				@output.c( line + "\n" )
			else
				@irc.message( from, line )
			end
		end
	end

	# Grab last seen
	def last( nick, user, host, from, msg, arguments, con )
		# Declare result string
		line = [ "" ]

		# Check if there is input
		if( !arguments.nil? && !arguments.empty? )
			arguments.gsub!( / /, "" )
			arguments.downcase!

			# Check if we have a log for this user
			if( !@seen[ arguments ].nil? )
				line = [
					@status.uptime( Time.now, @time[ arguments ] ) + " ago:" ,
					@seen[ arguments ]
				]
			else
				line = [ "No log for " + arguments + ". " + "Log goes back " + @status.uptime( Time.now, @first ) + "." ]
			end
		else
			line = [ "Please specify a nickname." ]
		end

		# Display result
		line.each do |l|
			if( con )
				@output.c( l + "\n" )
			else
				@irc.message( from, l )
			end
		end
	end

	# Grab beforelast seen
	def beforelast( nick, user, host, from, msg, arguments, con )
		# Declare result string
		line = [ "" ]

		# Check if there is input
		if( !arguments.nil? && !arguments.empty? )
			arguments.gsub!( / /, "" )
			arguments.downcase!

			# Check if we have a log for this user
			if( !@seen2[ arguments ].nil? )
				line = [
					@status.uptime( Time.now, @time2[ arguments ] ) + " ago:" ,
					@seen2[ arguments ]
				]
			else
				line = [ "No log for " + arguments + ". " + "Log goes back " + @status.uptime( Time.now, @first ) + "." ]
			end
		else
			line = [ "Please specify a nickname." ]
		end

		# Display result
		line.each do |l|
			if( con )
				@output.c( l + "\n" )
			else
				@irc.message( from, l )
			end
		end
	end

	# Add regular message to seen database
	def messaged( nick, user, host, from, message )
		line = nick  + " on " + from + ": " + message
		tmp = nick.downcase
		add( tmp, line )
	end

	# Add kick to seen database
	def kicked( nick, user, host, channel, kicked, reason )
		line = kicked + " was kicked from " + channel + " by " + nick + " (" + reason + ")."
		tmp = kicked.downcase
		add( tmp, line )
	end

	# Add join to seen database
	def joined( nick, user, host, channel )
		line = nick + " joined " + channel
		tmp = nick.downcase
		add( tmp, line )
	end

	# Add part to seen database
	def parted( nick, user, host, channel )
		line = nick + " parted " + channel
		tmp = nick.downcase
		add( tmp, line )
	end

	# Add quit to seen database
	def quited( nick, user, host, message )
		line = nick + " quit (" + message + ")"
		tmp = nick.downcase
		add( tmp, line )
	end

	# Meta function to force write
	def write( nick, user, host, from, msg, arguments, con )
		if( @config.auth( host, con ) )
			write_db

			if( con )
				@output.cinfo( "Wrote seen database to disk." )
			else
				@irc.notice( nick, "Wrote seen database to disk." )
			end
		end
	end

	# Function to send help about this plugin (Can also be called by the help plugin.)
	def help( nick, user, host, from, msg, arguments, con )
		help = [
			"This plugin provides data on the last seen times and actions of users.",
			"  seen last [user]            - Provides the last seen action from a user.",
			"  seen beforelast [user]      - Provides the second last seen action from a user.",
			"  seen [user]                 - Meta function that calls both of the above functions.",
			"  seen write                  - Force writing of seen database NOW."
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

	private

	# Function to add seen data to hashtable
	def add( user, line )
		# Move old data
		@seen2[ user ] = @seen[ user ]
		@time2[ user ] = @time[ user ]

		# Insert new data
		@seen[ user ] = line
		@time[ user ] = Time.new

		# Raise counter & write when needed
		increment
	end

	# Load database from disk
	def load_db
		# Declare datastore
		data = {}

		# Check if a database is stored on disk
		if File.exists?( @config.datadir + '/' + @filename )

			# Read database from file
        	File.open( @config.datadir + '/' + @filename ) do |file|
				data = Marshal.load( file )
			end

			# Load data into it's normal variables
			@first	= data[ "first" ]
			@seen	= data[ "seen" ]
			@time	= data[ "time" ]
			@seen2	= data[ "seen2" ]
			@time2	= data[ "time2" ]

		end

		# Clean up temp datastore
		data = nil
	end

	# Write database to disk
	def write_db
		data = {
			"first"	=> @first,
			"seen"	=> @seen,
			"time"	=> @time,
			"seen2"	=> @seen2,
			"time2"	=> @time2
		}

		File.open( @config.datadir + '/' + @filename, 'w' ) do |file|
			Marshal.dump( data, file )
		end
	end

	# Increment data counter + call write when needed
	def increment
		@current += 1

		if( @current >= @every )
			write_db
			@current = 0
		end
	end
end
