#!/usr/bin/env ruby

# Store links to a database and randomly retrieve one

# Input sanitation is done by wrapper.

# Plugin to add and view links
class Link
	
	# This method is called when the plugin is first loaded
	def initialize( status, config, output, irc, timer )
		@status		= status
		@config		= config
		@output		= output
		@irc		= irc
		@timer		= timer
	end

	# Default method, called when no argument is given (optional, but highly recomended)
	def main( nick, user, host, from, msg, arguments, con )
		link = ""
		id = ""
	
		begin
			rows = @config.my.query("SELECT link, id FROM links ORDER BY RAND() LIMIT 1")
			
			rows.each do |row|
				link = row[0]
				id = row[1]
			end
			
			@irc.message( from , "Link (#{id}): #{link}" )
		rescue
			@irc.message( from , "Error displaying link")
		end
	end

	# Function to send help about this plugin (Can also be called by the help plugin.)
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
		
	# Generic function that can be called by any user
	def add( nick, user, host, from, msg, arguments, con )
		chan_id = get_info( from, "chan", @config.chanhash)
		nick_id = get_info( nick, "nick", @config.nickhash)
		user_id = get_info( user, "user", @config.userhash)
		host_id = get_info( host, "host", @config.hosthash)
	
		insert_log = @config.my.prepare("INSERT INTO links (`nick`, `user`, `host`, `chan`, `link`) VALUES (?, ?, ?, ?, ?)")
		insert_log.execute( nick_id, user_id, host_id, chan_id, arguments)
		insert_log.close
		
		#@config.my.query("INSERT INTO `links` (`nick`, `host`, `link`) VALUES ((SELECT id FROM user WHERE nick = '" + nick + "' AND user = '" + user + "'), (SELECT id FROM host WHERE hostmask = '" + host + "'), '" + arguments + "')" )
		@irc.message( from , "#{user}: #{arguments} successfully added. Type !link Remove")
	end

	# Generic function that can be called by any user
	def remove( nick, user, host, from, msg, arguments, con )
		link_id = 0
		link_link = ""
		
		begin
			rows = @config.my.query( "SELECT * FROM links JOIN user ON links.nick = user.id JOIN host ON links.host = host.id WHERE user.nick = '#{nick}' AND user.user = '#{user}' AND host.hostmask ='#{host}' ORDER BY links.id DESC LIMIT 1;" )

			rows.each_hash(with_table = true) do |row|
				link_link = row["links.link"]
				link_id = row["links.id"]
			end
			@irc.message( from , "#{link_id}")
			@config.my.query("DELETE FROM links WHERE id = #{link_id};")
			@irc.message( from , "#{user}: #{link_link} has been deleted successfully. Type !link add to add another." )
		rescue
			@irc.message( from , "Error deleting link")
		end
	end
	
	# Generic function that can only be called by an admin
	def removeadmin( nick, user, host, from, msg, arguments, con )
		if( @config.auth( user, host, con ) )
			# Admin only code goes in here
			@irc.message( from, nick + " called \"function_admin\" from " + from + "." )
		else
			@irc.message( from, "Sorry " + nick + ", this is a function for admins only!" )
		end
	end

#############################################################################################
####                          Private functions start here.....                          ####
#############################################################################################

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
