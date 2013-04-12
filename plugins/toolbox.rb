#!/usr/bin/env ruby

# Plugin with some random small tools
class Toolbox
	require 'digest/md5'
	require 'digest/sha1'
	require 'net/http'
	require 'uri'

	# This method is called when the plugin is first loaded
	def initialize( status, config, output, irc, timer )
		@status		= status
		@config		= config
		@output		= output
		@irc		= irc
		@timer		= timer
	end

	# Redirect random nothing requests to help
	def main( nick, user, host, from, msg, arguments, con )
		line = "Not valid input. Please see the help function for valid commands."
		if( con )
			@output.c( line + "\n" )
		else
			@irc.notice( nick, line )
		end
	end

	# MD5 functions
	def md5( nick, user, host, from, msg, arguments, con )
		if( !arguments.nil? && !arguments.empty? )
			line = Digest::MD5.hexdigest( arguments )
			if( con )
				@output.c( line + "\n" )
			else
				@irc.message( from, line )
			end
		end
	end

	def lmd5( nick, user, host, from, msg, arguments, con )
		if( !arguments.nil? && !arguments.empty? )
			line = Net::HTTP.get( 'www.insomnia247.nl', '/hash_api.php?type=md5&hash=' + arguments )

			if( con )
				@output.c( line + "\n" )
			else
				@irc.message( from, line )
			end
		end
	end

	# SHA-1 functions
	def sha1( nick, user, host, from, msg, arguments, con )
		if( !arguments.nil? && !arguments.empty? )
			line = Digest::SHA1.hexdigest( arguments )
			if( con )
				@output.c( line + "\n" )
			else
				@irc.message( from, line )
			end
		end
	end

	def lsha1( nick, user, host, from, msg, arguments, con )
		if( !arguments.nil? && !arguments.empty? )
			line = Net::HTTP.get( 'www.insomnia247.nl', '/hash_api.php?type=sha1&hash=' + arguments )

			if( con )
				@output.c( line + "\n" )
			else
				@irc.message( from, line )
			end
		end
	end

	# Dig command
	def dig( nick, user, host, from, msg, arguments, con )
		valid = true
		reverse = false
		validtype = false

		types = [
			"A", "ANY", "AXFER", "CNAME", "MX", "NS", "PTR", "SOA", "TXT", "A6", "AAAA", "AFSDB", "APL", "ATMA", "CERT", 
			"DNAME", "DNSKEY", "DS", "EID", "GID", "GPOS", "HINFO", "ISDN", "KEY", "KX", "LOC", "MB", "MD", "MF", "MG", "MINFO", 
			"MR", "NAPTR", "NSEC", "NULL", "NSAP", "NSAP-PTR", "NXT", "OPT", "PX", "RP", "RRSIG", "RT", "SIG", "SINK", "SRV", 
			"SSHFP", "TKEY", "TSIG", "UID", "UINFO", "UNSPEC", "WKS", "X25"
		]

		cmd = ""

		if( !arguments.nil? && !arguments.empty? )
			args = arguments.split( ' ', 3 )

			# Determine what we have

			type	= nil
			addr	= nil
			ns		= nil

			args.each do |arg|
				if( arg =~ /^@/ )
					ns = arg.gsub( /^@/, "" )

					# Valid nameserver?
					if( type( ns ) == 0 )
						valid = false
					end

				# Check for reverse lookup
				elsif( arg =~ /^x$/i || arg =~ /^reverse$/i )
					type = "x"
					validtype = true

				# Check for valid host
				elsif( type( arg ) != 0 )
					addr = arg
				end

				# Check for valid lookup type
				types.each do |t|
					if( arg =~ /^#{t}$/i )
						type = t
						validtype = true
					end
				end
			end
		else
			valid = false
		end

		if( valid && !addr.nil? )
			# Build command string
			cmd = "dig +short "

			if( validtype && type == "x" )
				cmd = cmd + "-x "
			elsif( validtype )
				cmd = cmd + "-t " + type + " "
			else
				cmd = cmd + "-t A "
			end

			cmd = cmd + addr + " "

			if( !ns.nil? )
				cmd = cmd + "@" + ns
			end

			# Execute dig command
			output = `#{cmd}`

			if( output.nil? || output.empty? )
				output = "Error: No output received."
			end

			if( con )
				@output.c( output + "\n" )
			else
				@irc.message( from, output )
			end
			
		else
			line = "Not valid input."
			if( con )
				@output.c( line + "\n" )
			else
				@irc.message( from, line )
			end
		end
	end

	# PING command
	def ping( nick, user, host, from, msg, arguments, con )
		output = ""
		cmd = nil

		# Check if host is given
		if( !arguments.nil? && !arguments.empty? )

			# Check for valid host types
			case type( arguments )
			when 1
				cmd = "ping -c1 " + arguments
			when 4
				cmd = "ping -c1 " + arguments
			when 6
				cmd = "ping6 -c1 " + arguments
			else
				output = [ "" ,"Invalid host." ]
			end

			# Execute command
			if( !cmd.nil? )
				output = `#{cmd}`
				output = output.split( "\n", 3 )
			end

			if( output.nil? || output.empty? )
				output[1] = "Error: No output received."
			end

			# Show output
			if( con )
				@output.c( output[1] + "\n" )
			else
				@irc.message( from, output[1] )
			end
		else
			help( nick, user, host, from, msg, arguments, con )
		end
	end

	# Webchat IP decoder
	def webchat( nick, user, host, from, msg, arguments, con )
		output = ""
		if( !arguments.nil? && !arguments.empty? )
			arguments.gsub!( /[^a-fA-F0-9]/, "" )
			if( arguments.length == 8 )
				output =	arguments[ 0, 2 ].to_i(16).to_s(10) + "." +
							arguments[ 2, 2 ].to_i(16).to_s(10) + "." +
							arguments[ 4, 2 ].to_i(16).to_s(10) + "." +
							arguments[ 6, 2 ].to_i(16).to_s(10)


			else
				output = "Expecting 8 hex characters"
			end
		else
			output = "Expecting 8 hex characters"
		end

		# Show output
		if( con )
			@output.c( output + "\n" )
		else
			@irc.message( from, output )
		end
	end

	# Base change function
	def base( nick, user, host, from, msg, arguments, con )
		output = ""
		if( !arguments.nil? && !arguments.empty? )
			frombase, tobase, number = arguments.split( ' ', 3 )
			if( !frombase.nil? && !frombase.empty? && !tobase.nil? && !tobase.empty? && !number.nil? && !number.empty? )
				if( frombase.to_i < 2 || frombase.to_i > 36 || tobase.to_i < 2 || tobase.to_i > 36 )
					output = "Base number must be between 2 and 36."
				else
					output = number.to_i( frombase.to_i ).to_s( tobase.to_i )
				end
			else
				output = "Expecting 3 arguments."
			end
		else
			output = "Expecting 3 arguments."
		end

		# Show output
		if( con )
			@output.c( output + "\n" )
		else
			@irc.message( from, output )
		end
	end

	# (De-)HEX functions
	def hex( nick, user, host, from, msg, arguments, con )
		output = ""
		if( !arguments.nil? && !arguments.empty? )
			arguments.unpack('U'*arguments.length).each do |x|
				output = output + x.to_s( 16 ) + " "
			end

		else
			output = "Please provide string to convert."
		end

		# Show output
		if( con )
			@output.c( output + "\n" )
		else
			@irc.message( from, output )
		end
	end

	def dehex( nick, user, host, from, msg, arguments, con )
		output = ""	
		if( !arguments.nil? && !arguments.empty? )
			arguments.gsub!( /[^a-fA-F0-9]/, "" )
			arguments.scan(/../).each do |pair|
				output = output + pair.hex.chr
			end
		else
			output = "Please provide string to convert."
		end

		# Show output
		if( con )
			@output.c( output + "\n" )
		else
			@irc.message( from, output )
		end
	end

	# Alias method
	def unhex( nick, user, host, from, msg, arguments, con )
		dehex( nick, user, host, from, msg, arguments, con )
	end

	# (De-)decimal functions
	def dec( nick, user, host, from, msg, arguments, con )
		output = ""
		if( !arguments.nil? && !arguments.empty? )
			arguments.unpack('U'*arguments.length).each do |x|
				output = output + x.to_s( 10 ) + " "
			end
		else
			output = "Please provide string to convert."
		end

		# Show output
		if( con )
			@output.c( output + "\n" )
		else
			@irc.message( from, output )
		end
	end

	def dedec( nick, user, host, from, msg, arguments, con )
		output = ""	
		if( !arguments.nil? && !arguments.empty? )
			arguments.gsub!( /[^0-9]/, " " )
			arguments.split( ' ' ).each do |value|
				output = output + value.to_i.chr
			end
		else
			output = "Please provide string to convert."
		end

		# Show output
		if( con )
			@output.c( output + "\n" )
		else
			@irc.message( from, output )
		end
	end

	# Alias method
	def undec( nick, user, host, from, msg, arguments, con )
		dedec( nick, user, host, from, msg, arguments, con )
	end

	# Function to send help about this plugin (Can also be called by the help plugin.)
	def help( nick, user, host, from, msg, arguments, con )
		help = [
			"This plugin provides a series of simple tools.",
			"  toolbox md5 [phrase]                 - Calculate md5 hash of given phrase.",
			"  toolbox lmd5 [md5 hash]              - Do a database lookup for given md5 hash.",
			"  toolbox sha1 [phrase]                - Calculate sha1 hash of given phrase.",
			"  toolbox lsha1 [sha1 hash]            - Do a database lookup for given sha1 hash.",
			"  toolbox dig [host]                   - Do a (reverse) DNS lookup for a host.",
			"  toolbox ping [host]                  - Send a PING request to a host.",
			"  toolbox webchat [hexmask]            - Reverse webchat hex encoded IP address.",
			"  toolbox base [from] [to] [number]    - Convert base of number.",
			"  toolbox hex [string]                 - Translate string to hex. (UTF-8)",
			"  toolbox dehex [hex string]           - Translate hex to string.",
			"  toolbox dec [string]                 - Translate string to decimal values. (UTF-8)",
			"  toolbox dedec [string]               - Translate decimal values to string. (Non-numeric characters are used as delimiters.)"
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

	# Function to parse address type
	def type( host )
		if ( host =~ /^([[:alnum:]]+[.-]{0,1})+\.[[:alpha:]]{1,4}$/ )
			return 1
		elsif ( host =~ /^(([0-9]|[1-9][0-9]|1[0-9]{2}|2[0-4][0-9]|25[0-5])\.){3}([0-9]|[1-9][0-9]|1[0-9]{2}|2[0-4][0-9]|25[0-5])$/ )
			return 4
		elsif ( host =~ /^\s*((([0-9A-Fa-f]{1,4}:){7}([0-9A-Fa-f]{1,4}|:))|(([0-9A-Fa-f]{1,4}:){6}(:[0-9A-Fa-f]{1,4}|((25[0-5]|2[0-4]\d|1\d\d|[1-9]?\d)(\.(25[0-5]|2[0-4]\d|1\d\d|[1-9]?\d)){3})|:))|(([0-9A-Fa-f]{1,4}:){5}(((:[0-9A-Fa-f]{1,4}){1,2})|:((25[0-5]|2[0-4]\d|1\d\d|[1-9]?\d)(\.(25[0-5]|2[0-4]\d|1\d\d|[1-9]?\d)){3})|:))|(([0-9A-Fa-f]{1,4}:){4}(((:[0-9A-Fa-f]{1,4}){1,3})|((:[0-9A-Fa-f]{1,4})?:((25[0-5]|2[0-4]\d|1\d\d|[1-9]?\d)(\.(25[0-5]|2[0-4]\d|1\d\d|[1-9]?\d)){3}))|:))|(([0-9A-Fa-f]{1,4}:){3}(((:[0-9A-Fa-f]{1,4}){1,4})|((:[0-9A-Fa-f]{1,4}){0,2}:((25[0-5]|2[0-4]\d|1\d\d|[1-9]?\d)(\.(25[0-5]|2[0-4]\d|1\d\d|[1-9]?\d)){3}))|:))|(([0-9A-Fa-f]{1,4}:){2}(((:[0-9A-Fa-f]{1,4}){1,5})|((:[0-9A-Fa-f]{1,4}){0,3}:((25[0-5]|2[0-4]\d|1\d\d|[1-9]?\d)(\.(25[0-5]|2[0-4]\d|1\d\d|[1-9]?\d)){3}))|:))|(([0-9A-Fa-f]{1,4}:){1}(((:[0-9A-Fa-f]{1,4}){1,6})|((:[0-9A-Fa-f]{1,4}){0,4}:((25[0-5]|2[0-4]\d|1\d\d|[1-9]?\d)(\.(25[0-5]|2[0-4]\d|1\d\d|[1-9]?\d)){3}))|:))|(:(((:[0-9A-Fa-f]{1,4}){1,7})|((:[0-9A-Fa-f]{1,4}){0,5}:((25[0-5]|2[0-4]\d|1\d\d|[1-9]?\d)(\.(25[0-5]|2[0-4]\d|1\d\d|[1-9]?\d)){3}))|:)))(%.+)?\s*$/)
			return 6
		else
			return 0
		end
	end
end
