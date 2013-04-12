#!/usr/bin/env ruby

# Plugin that makes use of the Bing! translate API.
class Translate

	# This method is called when the plugin is first loaded
	def initialize( status, config, output, irc, timer )
		@status		= status
		@config		= config
		@output		= output
		@irc		= irc
		@timer		= timer

		@appid		= ""
		@filename	= "translate.appid"

		# Load AppId
		loadid
	end

	# Default method, alias for 'to'
	def main( nick, user, host, from, msg, arguments, con )
		to( nick, user, host, from, msg, arguments, con )
	end

	# Function to translate from one language to another
	def to( nick, user, host, from, msg, arguments, con )
		if( !arguments.nil? && !arguments.empty? )
			to, string = arguments.split( ' ', 2 )
	
			if( !string.nil? )
				string.gsub!( / /, "%20" ) # Replace spaces
				string.gsub!( /&/, "" ) # Sanitize GET variables

				# Send GET request
				line = Net::HTTP.get( 'api.microsofttranslator.com', '/v2/Http.svc/Translate?appId=' + @appid + '&to=' + to + '&text=' + string + '&contentType=text/plain' )

				# Catching some common errors
				if( line =~ /'to' must be a valid language/ )
					line = "Error: Invalid language code specified."
				elsif( line =~ /'from' must be a valid language/ )
					line = "Error: Could not detect language to translate from."
				end
					
				# Clean up output
				line.gsub!( /(<string(.+?)>)|(<\/string>)|(\n)|(\r)/, "" )
				line.gsub!( /(<(.+?)>)|(<\/(.+?))/, " " )
				line.gsub!( /  /, " " )
			else
				line = "Not valid input. Please see the help function for valid commands."
			end

			if( line.nil? || line.empty? )
				line = "Error: No result. (Probably wrong language code.)"
			end

			if( con )
				@output.c( line + "\n" )
			else
				@irc.message( from, line )
			end
		end
	end

	# Function to detect the language of a provided string
	def detect( nick, user, host, from, msg, arguments, con )
		if( !arguments.nil? && !arguments.empty? )
			arguments.gsub!( / /, "%20" ) # Replace spaces
			arguments.gsub!( /&/, "" ) # Sanitize GET variables

			# Send request
			line = Net::HTTP.get( 'api.microsofttranslator.com', '/v2/Http.svc/Detect?appId=' + @appid + '&text=' + arguments )

			# Clean up output
			line.gsub!( /(<string(.+?)>)|(<\/string>)|(\n)|(\r)/, "" )
			line.gsub!( /(<(.+?)>)|(<\/(.+?))/, " " )
			line.gsub!( /  /, " " )
		else
			line = "Not valid input. Please see the help function for valid commands."
		end

		if( line.nil? || line.empty? )
			line = "Error: No result. (Language not detectable.)"
		end

		if( con )
			@output.c( line + "\n" )
		else
			@irc.message( from, line )
		end
	end

	# Function to send help about this plugin
	def help( nick, user, host, from, msg, arguments, con )
		help = [
			"This plugin provides an interface to the Bing! translate API.",
			"  translate to [lang] [phrase]         - Translate a given phrase into another language.",
			"  translate detect [prase]             - Detect the language of the provided phrase.",
			"  translate help                       - Show this help.",
			" ",
			"  Valid language codes available here: http://wiki.insomnia247.nl/wiki/Nanobot_translate"
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

	# Load the AppId from a file
	def loadid
		# Check if a appid is stored on disk
		if File.exists?( @config.datadir + '/' + @filename )

			# Read database from file
        	file = File.open( @config.datadir + '/' + @filename )
			
			file.each do |line|
				@appid << line
			end
			@appid.gsub!( /[^0-9a-zA-Z]/, "" )

			file.close
		else
			@output.bad( "Could not load AppId from #{@config.datadir}/#{@filename} for translate plugin." )
		end
	end
end
