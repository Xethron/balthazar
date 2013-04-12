#!/usr/bin/env ruby

# New Plugin for logging all chats to MySQL DB.

# Input sanitation is done by wrapper.

# Plugin to demonstrate the working of plugins
class Logs
	
	# This method is called when the plugin is first loaded
	def initialize( status, config, output, irc, timer )
		@status		= status
		@config		= config
		@output		= output
		@irc		= irc
		@timer		= timer
		@userinfo	= status.getplugin( "user" ) 
	end

	# Method that receives a notification when a user is kicked (optional)
	def kicked( nick, user, host, channel, kicked, reason )
		chan_id = get_info( channel, "chan", @config.chanhash)
		nick_id = get_info( nick, "nick", @config.nickhash)
		kick_id = get_info( kicked, "nick", @config.nickhash)
		user_id = get_info( user, "user", @config.userhash)
		host_id = get_info( host, "host", @config.hosthash)
	
		insert_log = @config.my.prepare("INSERT INTO kicks (`nick`, `user`, `host`, `chan`, `kicked`, `reason`) VALUES (?, ?, ?, ?, ?, ?)")
		insert_log.execute( nick_id, user_id, host_id, chan_id, kick_id, reason)
		insert_log.close
		reason = @config.my.escape_string(reason)
	end

	# Method that receives a notification when a notice is received (optional)
#	def noticed( nick,  user,  host,  to,  message )
#		@irc.message( nick, "Received notice from: " + nick + ": " + message )
#	end

	# Method that receives a notification when a message is received, that is not a command (optional)
	def messaged( nick, user, host, from, message )
		if( message =~ /^\001ACTION (.+)/ )
			msg_type = "2"
			message = $1
		else
			msg_type = "1"
		end
		
		smileys = message.scan(/([>]?[:;8xX][-]?[)(dDoO0S$Ppqc|\\\/]|[:]['][(]|[D][:]|d-_-b|\b[0oO][_\.]?[0oO]\b|[\\\/]?[0Oo][\\\/]|[\\\/][0Oo])/)
		smileys.each do |smile|
			gsmile[smile] += 1
			usmile[nick.][smile] += 1
		
		chan_id = get_info( from, "chan", @config.chanhash)
		nick_id = get_info( nick, "nick", @config.nickhash)
		user_id = get_info( user, "user", @config.userhash)
		host_id = get_info( host, "host", @config.hosthash)
	
		insert_log = @config.my.prepare("INSERT INTO logs (`type`, `from`, `nick`, `user`, `host`, `message`) VALUES (?, ?, ?, ?, ?, ?)")
		insert_log.execute( msg_type, chan_id, nick_id, user_id, host_id, message)
		insert_log.close
	end

	# Method that receives a notification when a user joins (optional)
	def joined( nick, user, host, channel )
		chan_id = get_info( channel, "chan", @config.chanhash)
		nick_id = get_info( nick, "nick", @config.nickhash)
		user_id = get_info( user, "user", @config.userhash)
		host_id = get_info( host, "host", @config.hosthash)
	
		insert_log = @config.my.prepare("INSERT INTO joins (`nick`, `user`, `host`, `chan`) VALUES (?, ?, ?, ?)")
		insert_log.execute( nick_id, user_id, host_id, chan_id)
		insert_log.close
	end

	# Method that receives a notification when a user parts (optional)
	def parted( nick, user, host, channel )
		chan_id = get_info( channel, "chan", @config.chanhash)
		nick_id = get_info( nick, "nick", @config.nickhash)
		user_id = get_info( user, "user", @config.userhash)
		host_id = get_info( host, "host", @config.hosthash)
	
		insert_log = @config.my.prepare("INSERT INTO parts (`type`, `nick`, `user`, `host`, `chan`) VALUES (1, ?, ?, ?, ?)")
		insert_log.execute( nick_id, user_id, host_id, chan_id)
		insert_log.close
	end

	# Method that receives a notification when a user parts (optional)
	def partedreason( nick, user, host, channel, reason )
		chan_id = get_info( channel, "chan", @config.chanhash)
		nick_id = get_info( nick, "nick", @config.nickhash)
		user_id = get_info( user, "user", @config.userhash)
		host_id = get_info( host, "host", @config.hosthash)
	
		insert_log = @config.my.prepare("INSERT INTO parts (`type`, `nick`, `user`, `host`, `chan`, `reason`) VALUES (2, ?, ?, ?, ?, ?)")
		insert_log.execute( nick_id, user_id, host_id, chan_id, reason)
		insert_log.close
	end

	# Method that receives a notification when a user quits (optional)
	def quited( nick, user, host, message )
		nick_id = get_info( nick, "nick", @config.nickhash)
		user_id = get_info( user, "user", @config.userhash)
		host_id = get_info( host, "host", @config.hosthash)
	
		insert_log = @config.my.prepare("INSERT INTO parts (`type`, `nick`, `user`, `host`, `chan`, `reason`) VALUES (3, ?, ?, ?, 0, ?)")
		insert_log.execute( nick_id, user_id, host_id, message)
		insert_log.close
	end

	# Method that receives a notification when a user quits (optional)
	def renamed( nick, user, host, newnick )
		nick_id = get_info( nick, "nick", @config.nickhash)
		new_nick_id = get_info( newnick, "nick", @config.nickhash)
		user_id = get_info( user, "user", @config.userhash)
		host_id = get_info( host, "host", @config.hosthash)
	
		insert_log = @config.my.prepare("INSERT INTO renames (`nick`, `user`, `host`, `newnick`) VALUES (?, ?, ?, ?)")
		insert_log.execute( nick_id, user_id, host_id, new_nick_id)
		insert_log.close
	end

	# Function to send help about this plugin (Can also be called by the help plugin.) jKyrT5962Fj
	def help( nick, user, host, from, msg, arguments, con )
		help = [
			"This plugin demonstrates the working of plugins.",
			"  demo function               - Public plugin function.",
			"  demo adminfunction          - Admin only plugin function"
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

	# Private functions start here.....
	private
	# If user/chan information is not yet added into DB, add it.
	def add_info( value, type )
		begin
			@output.good( "Adding: #{value}\n" )
			set_info = @config.my.prepare("INSERT INTO `#{type}s` SET `value` = ?")
			set_info.execute( value )
			set_info.close

			get_info = @config.my.prepare "SELECT `id` FROM `#{type}s` WHERE `value` = ?"
			get_info.execute( value )
			result = get_info.fetch
			get_info.close
			@output.good( "#{type} added: #{value} - id: #{result[0]}\n" )
			return result[0]
		rescue
			@output.bad("Error adding #{type} (#{value}) to database.\n")
		end
	end

	def get_info (value, type, hash)
		if(hash[value.downcase])
			return hash[value.downcase]
		else
			hash[value.downcase] = add_info(value, type)
			return hash[value.downcase]
		end
	end
end
