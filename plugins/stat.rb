#!/usr/bin/env ruby

# Generate live stats from the logs.

# Input sanitation is done by wrapper.

# Calling actions from the DB
class Stat
	
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
		line = "#{arguments} "
		#@irc.notice( nick, "Starting Main." )
		ararg = Array.new
		arr_res = Array.new
		ari = 0

		res_pre = "#{nick}: "
		res_post = ""
		sql_where = "`from` != 1"
		
		### CHECK IF THIS IS A SEARCH ###
		if (line =~ /-(s|ns|r|nr) "(.+)" /)
		
			sql_sel = "COUNT( * ) FROM `logs`"
			num_res = 0
			arr_res[0] = "SEARCH 6"
			
			if (line =~ /-s "(.+?)" /) ## Like Search ##
				arr_res[0] = "#{arr_res[0]}|LIKE #{$1}|"
				sql_where = "#{sql_where} AND `message` LIKE ?"
				ararg[ari] = $1
				ari += 1
			end
			if (line =~ /-ns "(.+?)" /) ## Not Like Search ##
				arr_res[0] = "#{arr_res[0]}|NOT LIKE #{$1}|"
				sql_where = "#{sql_where} AND `message` NOT LIKE ?"
				ararg[ari] = $1
				ari += 1
			end
			if (line =~ /-r "(.+?)" /) ## RegExp Search ##
				arr_res[0] = "#{arr_res[0]}|REGEXP #{$1}|"
				sql_where = "#{sql_where} AND `message` REGEXP ?"
				ararg[ari] = $1
				ari += 1
			end
			if (line =~ /-nr "(.+?)" /) ## Not RegExp Search ##
				arr_res[0] = "#{arr_res[0]}|NOT REGEXP #{$1}|"
				sql_where = "#{sql_where} AND `message` NOT REGEXP ?"
				ararg[ari] = $1
				ari += 1
			end
			#arr_res[0] = "#{arr_res[0]}"
		else ## No Search ##
			sql_sel = "SUM( LENGTH(message) ), SUM( LENGTH(message) - LENGTH(REPLACE(message, ' ', ''))+1), COUNT( * ) FROM `logs`"
			num_res = 2
			arr_res[0] = "Characters"
			arr_res[1] = "Words"
			arr_res[2] = "Lines"
		end
		### GET THE TIME PERIOD ###
		
		if( line == " " ) # Assume he wants info about himself for today
			line = "-" # Adding unwanted character for any further if statements
			req_nick = nick
			if(nick_id = @config.nickhash[req_nick.downcase])
				sql_where = "#{sql_where} AND `time` BETWEEN CONCAT(CURDATE(), ' 00:00:00') AND CONCAT(CURDATE(), ' 23:59:59') AND `nick` = ?"
				ararg[ari] = nick_id
				ari += 1
				res_pre = "#{res_pre}[Today][Nick: #{nick}]"
			end
		elsif( line == "- " ) # Assume he wants info about himself for today in current channel
			line = "-" # Adding unwanted character for any further if statements
			req_nick = nick
			if(nick_id = @config.nickhash[req_nick.downcase])
				sql_where = "#{sql_where} AND `time` BETWEEN CONCAT(CURDATE(), ' 00:00:00') AND CONCAT(CURDATE(), ' 23:59:59') AND `nick` = ?"
				ararg[ari] = nick_id
				ari += 1
				res_pre = "#{res_pre}[Today][Nick: #{nick}]"
			end
			req_chan = from
			chan_id = @config.chanhash[req_chan.downcase]
			sql_where = "#{sql_where} AND `from` = ?"
			ararg[ari] = chan_id
			ari += 1
			res_pre = "#{res_pre}[#{from}]"
		elsif( line =~ /^today (.*)/ )
			line = $1
			sql_where = "#{sql_where} AND `time` BETWEEN CONCAT(CURDATE(), ' 00:00:00') AND CONCAT(CURDATE(), ' 23:59:59')"
			res_pre = "#{res_pre}[Today]"
		elsif( line =~ /^yest (.*)/ )
			line = $1
			sql_where = "#{sql_where} AND `time` BETWEEN CONCAT(CURDATE() - INTERVAL 1 DAY, ' 00:00:00') AND CONCAT(CURDATE() - INTERVAL 1 DAY, ' 23:59:59')"
			res_pre = "#{res_pre}[Yesterday]"
		elsif( line =~ /^24h (.*)/ )
			line = $1
			sql_where = "#{sql_where} AND `time` BETWEEN CONCAT(CURDATE() - INTERVAL 1 DAY, ' ', CURTIME()) AND CONCAT(CURDATE(), ' ', CURTIME())"
			res_pre = "#{res_pre}[Past 24 hours]"
		elsif( line =~ /^week (.*)/ )
			line = $1
			sql_where = "#{sql_where} AND `time` BETWEEN CONCAT(CURDATE() - INTERVAL 1 WEEK, ' ', CURTIME()) AND CONCAT(CURDATE(), ' ', CURTIME())"
			res_pre = "#{res_pre}[Past week]"
		elsif( line =~ /^month (.*)/ )
			line = $1
			sql_where = "#{sql_where} AND `time` BETWEEN CONCAT(CURDATE() - INTERVAL 1 MONTH, ' ', CURTIME()) AND CONCAT(CURDATE(), ' ', CURTIME())"
			res_pre = "#{res_pre}[Last Month]"
		elsif( line =~ /^all (.*)/ )
			line = $1
			res_pre = "#{res_pre}[Since 2012-06-19]"
		elsif( line =~ /-d (\d{4})-(\d{2})-(\d{2}) (\d{2}):(\d{2}):(\d{2}) (\d{4})-(\d{2})-(\d{2}) (\d{2}):(\d{2}):(\d{2}) (.*)/ )
			line = $13
			sql_where = "#{sql_where} AND `time` BETWEEN ? AND ?"
			ararg[ari] = "#{$1}-#{$2}-#{$3} #{$4}:#{$5}:#{$6}"
			ari += 1
			ararg[ari] = "#{$7}-#{$8}-#{$9} #{$10}:#{$11}:#{$12}"
			ari += 1
			res_pre = "#{res_pre}[Between #{ararg[ari-2]} and #{ararg[ari-1]}]"
		else
			#@irc.message( from, "ERROR: Invalid date string or time selection." )
			#res_pre = "#{res_pre} Since 2012-06-19;"
			sql_where = "#{sql_where} AND `time` BETWEEN CONCAT(CURDATE(), ' 00:00:00') AND CONCAT(CURDATE(), ' 23:59:59')"
			res_pre = "#{res_pre}[Today]"
		end
		#@irc.notice( nick, "-#{line}-" )
		### GET ANY OTHER ARGUMENTS ###

		if( line =~ /^([^-#$?].+?) / )
			req_nick = $1
			#@irc.notice( nick, "Nick-#{$1}-" )
			#@irc.message( from, "Nick #{req_nick}" )
			if(nick_id = @config.nickhash[req_nick.downcase])
				sql_where = "#{sql_where} AND `nick` = ?"
				ararg[ari] = nick_id
				ari += 1
				res_pre = "#{res_pre}[Nick: #{req_nick}]"
			end
		end
		if( line =~ /-n (.+?) / )
			req_nick = $1
			#@irc.message( from, "-n #{req_nick}" )
			if(nick_id = @config.nickhash[req_nick.downcase])
				sql_where = "#{sql_where} AND `nick` = ?"
				ararg[ari] = nick_id
				ari += 1
				res_pre = "#{res_pre}[Nick: #{req_nick}]"
			end
		end
		if( line =~ /-u (.+?) / )
			req_user = $1
			#@irc.message( from, "-u #{req_user}" )
			if(user_id = @config.userhash[req_user.downcase])
				sql_where = "#{sql_where} AND `user` = ?"
				ararg[ari] = user_id
				ari += 1
				res_pre = "#{res_pre}[User: #{req_user}]"
			end
		end
		if( line =~ /-h (.+?) / )
			req_host = $1
			#@irc.notice( nick, "-#{$1}-" )
			#@irc.message( from, "-h #{req_host}" )
			if(host_id = @config.hosthash[req_host.downcase])
				sql_where = "#{sql_where} AND `host` = ?"
				ararg[ari] = host_id
				ari += 1
				res_pre = "#{res_pre}[Host: #{req_host}]"
			end
		end
		if( line =~ /#(.+?) / )
			req_chan = "\##{$1}"
			#@irc.notice( nick, "-#{$1}-" )
			#@irc.message( from, "# #{req_chan}" )
			if(chan_id = @config.chanhash[req_chan.downcase])
				sql_where = "#{sql_where} AND `from` = ?"
				ararg[ari] = chan_id
				ari += 1
				res_pre = "#{res_pre}[Channel: #{req_chan}]"
			else
				res_pre = "#{res_pre}[4Channel #{req_chan} Not Found!][All Channels]"
			end
		else
			res_pre = "#{res_pre}[All Channels]"
		end
		if( line =~ /\$(.+?) / )
			if( line =~ /\$msg/ )
				sql_where = "#{sql_where} AND `type` = 1"
				res_pre = "#{res_pre}[Messages Only]"
			elsif( line =~ /\$action/ )
				sql_where = "#{sql_where} AND `type` = 2"
				res_pre = "#{res_pre}[Actions Only]"
			end
		end
		#@irc.message( from, "SELECT #{sql_sel} WHERE #{sql_where}" )
		#@irc.message( from, "#{res_output}" )
		get_info = @config.my.prepare ( "SELECT #{sql_sel} WHERE #{sql_where}" )
		#@irc.message( from, "#{ararg}" )
		get_info.execute( *ararg )
		result = get_info.fetch
		res_output = "#{res_pre} |"
		for i in 0..num_res
			res_output = "#{res_output}| #{result[i]} #{arr_res[i]} |"
		end
		#@irc.message( from, "#{result}" )
		#res_output = "#{res_output} #{res_post}"
		#@irc.message( from, "7" )
		#@output.good( "#{result[0]} characters in #{result[1]} words in #{result[2]} lines.\n" )
		@irc.message( from, res_output )
		get_info.close
	end
	
	def help( nick, user, host, from, msg, arguments, con )
		if( arguments.nil? || arguments.empty? )
			# General help
			help = [
				"#{@config.command}stat generates any stat imaginable with data collected from 2012-06-19",
				"  HELP: #{@config.command}stat help usage        -- Shows how to use the command",
				"  HELP: #{@config.command}stat help time         -- Shows available time options",
				"  HELP: #{@config.command}stat help options      -- Shows available paramaters",
				"  HELP: #{@config.command}stat help search       -- Details on how to use search",
				"  HELP: #{@config.command}stat help regexp       -- Advansed users only! Details on MySQL Regular expressions",
				"  HELP: #{@config.command}stat help examples     -- Gives you a couple of examples",
				" -"
			]
		else
			# Specific help
			case arguments
			when "usage"
				help = [
					"#{@config.command}stat usage. [] specifies optional values.",
					"  USAGE 1: #{@config.command}stat [-]                    -- Gives you your own stats for today, \"-\" specifies current channel only.",
					"  USAGE 2: #{@config.command}stat [TIME][NICK][OPTIONS]  -- Gives detailed information",
					"    No time defaults to today.",
					"    No nick defaults to everyone",
					"    Options narrows results, lack thereof includes all the posibilities",
					"    No time, nick or option defaults to USAGE 1."
				]
			when "time"
				help = [
					"Adding no time defaults to today. Time should always be added first.",
					"#{@config.command}stat [TIME][NICK][OPTIONS]",
					"  today                      -- Gives stats for for today only. From 00:00:00 untill current time.",
					"  24h                        -- Gives stats for the past 24 h.",
					"  yest                       -- Gives stats for the previous day. From 00:00:00 yesterday till 23:59:59",
					"  week                       -- Gives stats for the past 7 days!",
					"  month                      -- Gives stats for the past month!!",
					"  all                        -- Gives stats since 2012-06-19!!!",
					"  -d yyyy-mm-dd hh:mm:ss yyyy-mm-dd hh:mm:ss -- Gives stats between the two time periods",
					"  Only one option per query..."
				]
			when "options"
				help = [
					"Options act as filters. Adding no option means more results. Options can be combined!",
					"#{@config.command}stat [TIME][NICK][OPTIONS]",
					"  -n [nick]           -- Searches for the specified nickname",
					"  -u [user]           -- Searches for the specified username",
					"  -h [host]           -- Searches for the specified hostmask",
					"  #[channel]          -- Limits stats to the given channel",
					"  $msg                -- Only look for regular messages",
					"  $action             -- Only look for actions",
					"  -s \"SEARCH TEXT\"  -- Show the occurance of a specific line/word - '_' means any 1 character, and '%' means any number of any characters.",
					"  -ns \"SEARCH TEXT\" -- Same as -s, but looks for lines NOT containing that text.",
					"  -r \"REGEXP\"       -- ADVANCED USERS ONLY",
					"  -nr \"REGEXP\"      -- ADVANCED USERS ONLY: Same as -r, but includes lines not containing that REGEXP"
				]
			when "search"
				help = [
					"-s searches for words or phrases that might have been used...",
					"  % means any number (including 0) or any character.",
					"  _ means exactly 1 of any character",
					"EXAMPLES:",
					"  -s \"Hello\"        -- Searches for a line that contains Hello and ONLY Hello in the line.",
					"  -s \"Hello%\"       -- Searches for a line beginning with Hello: Hello, Hello there...",
					"  -s \"Hello_\"       -- Searches for a line beginning with Hello and has one other character of any form: Hello., Hello!, Helloo",
					"  -s \"___\"          -- Searches for a line containing 3 characters: hey, meh, ..., !!!"
				]
			when "regexp"
				help = [
					"Regular Expressions match complex combinations of strings.",
					"  -r \"REGEXP\" will search for strings matching this REGEXP",
					"  -r \"REGEXP\" will search for strings NOT matching this REGEXP",
					"  For details on MySQL REGEXP, read this: http://dev.mysql.com/doc/refman/5.0/en/regexp.htm"
				]
			when "examples"
				help = [
					"Examples are still being made: Here is a few to keep you busy.",
					"#{@config.command}stat              -- Gives your stats for today in all the channels the bot watches.",
					"#{@config.command}stat -            -- Gives your stats for today for current channel only",
					"#{@config.command}stat today        -- Gives all the stats for today in all the channels the bot watches.",
					"#{@config.command}stat yest #{nick} -- Gives stats for #{nick} from yesterday in all the channels the bot watches.",
					"#{@config.command}stat 24h #{nick} -u #{user} -h #{host} #{from} $Action -- Gives stats for #{nick} with username: #{user} and host: #{host} from channel: #{from} in the last 24 hours.",
					"#{@config.command}stat -h #{host} #{from} $msg -s \"%love%\" -- Gives stats host: #{host} from channel: #{from} containing love in a message (Not a action) for today only."
				]
			end
		end
		# Print out help
		k=2
		help.each do |line|
			if( con )
				@output.c( line + "\n" )
			else
				@irc.notice( nick, line )
				sleep(k)
				k += 0.2
			end
		end
	end
end
