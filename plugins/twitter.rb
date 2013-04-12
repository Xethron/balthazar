#!/usr/bin/env ruby
# coding: utf-8

# Plugin to grab latest message from a twitter feed

require 'cgi'
class Twitter

	# This method is called when the plugin is first loaded
	def initialize( status, config, output, irc, timer )
		@status		= status
		@config		= config
		@output		= output
		@irc		= irc
		@timer		= timer

		if( @status.threads && @config.threads)
			# Variables for following users
			@follow		= {}
			@filename	= "twitter.data"
			@announce	= "#news"
			@freq		= 300
			@extra_line	= true

			@specials	= {	"&#8211;"	=> "–",
							"&#8212;"	=> "—",
							"&#8216;"	=> "‘",
							"&#8217;"	=> "’",
							"&#8218;"	=> "‚",
							"&#8220;"	=> "“",
							"&#8221;"	=> "”",
							"&#8222;"	=> "„",
							"&#8224;"	=> "†",
							"&#8225;"	=> "‡",
							"&#8226;"	=> "•",
							"&#8230;"	=> "…",
							"&#8240;"	=> "‰",
							"&#8364;"	=> "€",
							"&euro;"	=> "€",
							"&#8482;"	=> "™",
							"&gt;"		=> ">",
							"&lt;"		=> "<"}
			
			# Load database of users being followed
			load_db

			@ftread		= Thread.new{ follow_thread }
		end
	end

	# Meta method for getlast
	def main( nick, user, host, from, msg, arguments, con )
		getlast( nick, user, host, from, msg, arguments, con )
	end

	# Method that receives a notification when a user is kicked (optional)
	def getlast( nick, user, host, from, msg, arguments, con )
		if( !arguments.nil? && !arguments.empty? )
			arguments.gsub!( /&/, "" ) # Sanitize GET variables

			# Retreive XML
			line = Net::HTTP.get( 'twitter.com', '/statuses/user_timeline/' + arguments + '.rss' )

			# Parse out XML (needs better regex)
			if( line =~ /<item>\n    <title>(.+?)<\/title>/is )
				line = $1
				line = CGI.unescapeHTML( line )
				@specials.each_key do |key|
					line.gsub!( key, @specials[key] )
				end
			else
				line = "Error: No result."
			end
		else
			line = "Not valid input. Expecting twitter username."
		end

		if( con )
			@output.c( line + "\n" )
		else
			@irc.message( from, line )
		end
	end

	# Method to add users to follow
	def follow( nick, user, host, from, msg, arguments, con )
		if( @config.auth( user, host, con ) )
			if( @status.threads && @config.threads)
				if( !arguments.nil? && !arguments.empty? )
					arguments.gsub!( /&/, "" ) # Sanitize GET variables
				
					# Retreive XML
					line = Net::HTTP.get( 'twitter.com', '/statuses/user_timeline/' + arguments + '.rss' )

					# Parse out XML (needs better regex, or a real XML parser, realistically)
					if( line =~ /<item>\n    <title>(.+?)<\/title>/is )
						line = $1
						@follow[ arguments ] = line

						line = CGI.unescapeHTML( line )
						@specials.each_key do |key|
							line.gsub!( key, @specials[key] )
						end

						line = "Following: " + line

						# Write database to disk
						write_db
					else
						line = "Error: No result."
					end
				else
					line = "Not valid input. Expecting twitter username."
				end
			else
				line = "Follow functions not available when threading is disabled."
			end
		else
			line = "You aren't allowed to add users."
		end

		# Show output
		if( con )
			@output.c( line + "\n" )
		else
			@irc.message( from, line )
		end
	end

	# Method to delete users to follow
	def unfollow( nick, user, host, from, msg, arguments, con )
		if( @config.auth( user, host, con ) )
			if( @status.threads && @config.threads)
				if( !arguments.nil? && !arguments.empty? )
					arguments.gsub!( /&/, "" ) # Sanitize

					# Check if user is being followed
					if( @follow.has_key?( arguments ) )
						@follow[ arguments ] = nil
						@follow.delete( arguments )
						line = "Unfollowed " + arguments + "."

						# Write database to disk
						write_db
					else
						line = "User isn't being followed."
					end
				else
					line = "Not valid input. Expecting twitter username."
				end
			else
				line = "Follow functions not available when threading is disabled."
			end
		else
			line = "You aren't allowed to add users."
		end

		# Show output
		if( con )
			@output.c( line + "\n" )
		else
			@irc.message( from, line )
		end
	end

	# Method stop feed collection
	def stop( nick, user, host, from, msg, arguments, con )
		if( @config.auth( user, host, con ) )
			if( @status.threads && @config.threads)
				@ftread.exit
				line = "Feed collection stopped."
			else
				line = "Feeds are not being collected. (No threading available.)"
			end
		else
			line = "You are not authorized to perform this action."
		end

		# Show output
		if( con )
			@output.c( line + "\n" )
		else
			@irc.message( from, line )
		end
	end

	# Set channel for feeds
	def channel( nick, user, host, from, msg, arguments, con )
		if( @config.auth( user, host, con ) )
			if( !arguments.nil? && !arguments.empty? )
				if( @status.threads && @config.threads)
					@announce = arguments
					line = "Set new channel to " + arguments + "."
				else
					line = "Feeds are not being collected. (No threading available.)"
				end
			else
				line = "Expecting channel name."
			end
		else
			line = "You are not authorized to perform this action."
		end

		# Show output
		if( con )
			@output.c( line + "\n" )
		else
			@irc.message( from, line )
		end
	end

	# Show list of accounts being followed
	def following( nick, user, host, from, msg, arguments, con )
		line = ""
		if( @status.threads && @config.threads)
			@follow.each do |user, last|
				line = line + user + " "
			end
		else
			line = "Not following anyone. (No threading.)"
		end

		if( con )
			@output.c( line + "\n" )
		else
			@irc.notice( nick, line )
		end
	end

	# Function to send help about this plugin (Can also be called by the help plugin.)
	def help( nick, user, host, from, msg, arguments, con )
		help = [
			"This plugin retrieves the last message from a users twitter feed.",
			"  twitter getlast [twittername]     - Public plugin function.",
			"  twitter follow [twittername]      - Follow twitter user.",
			"  twitter unfollow [twittername]    - Unfollow twitter user.",
			"  twitter following                 - Show list of accounts being followed.",
			"  twitter channel [channel]         - Set channel for followed feeds.",
			"  twitter stop                      - Stop feed collection.",
			"  twitter help                      - Show this help"
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
	# Load database from disk
	def load_db
		# Check if a database is stored on disk
		if File.exists?( @config.datadir + '/' + @filename )

			# Read database from file
        	File.open( @config.datadir + '/' + @filename ) do |file|
				@follow = Marshal.load( file )
			end
		end

	end

	# Write database to disk
	def write_db
		File.open( @config.datadir + '/' + @filename, 'w' ) do |file|
			Marshal.dump( @follow, file )
		end
	end

	# Function for thread that checks updates for users being followed
	def follow_thread
		while true
			# Loop trough users
			@follow.each do |user, last|
				begin
					# Retreive XML
					line = Net::HTTP.get( 'twitter.com', '/statuses/user_timeline/' + user + '.rss' )

					# Parse out XML (needs better regex)
					if( line =~ /<item>\n    <title>(.+?)<\/title>/is )
						line = $1
					end

					# Check against last message
					if( line != last )
						# Check for feed failures
						if( line !~ /\<\?xml version=\"1\.0\" encoding=\"UTF-8\"\?\>/ )
							@follow[ user ] = line

							# Special char parsing
							line = CGI.unescapeHTML( line )
							@specials.each_key do |key|
								line.gsub!( key, @specials[key] )
							end

							@irc.message( @announce, line )

							# Formating for output
							if( @extra_line )
								@irc.message( @announce, " " )
							end
							write_db
						end
					end
				rescue
					# Silently fail
					@output.debug( "Failure while retreiving " + user + " feed." )
				end
			end

			# Wait before checking for updates again
			sleep( @freq )
		end
	end
end
