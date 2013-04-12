#!/usr/bin/env ruby

# Show the top chatters for a specific search

# Input sanitation is done by wrapper.

# Calling actions from the DB
class Top
	
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
		#@irc.message( from, "Arguments = \"#{arguments}\"" )
		
		sql_select = "SELECT nicks.value" #, COUNT(*) AS cnt FROM `logs` JOIN `nicks` ON nicks.id = logs.nick GROUP BY `nick` ORDER BY cnt DESC LIMIT 10"
		sql_from = "FROM `logs` JOIN `nicks` ON nicks.id = logs.nick"
		sql_where = "WHERE nick NOT IN (7,9) AND `from` != 1"
		sql_post = "GROUP BY `nick` ORDER BY cnt DESC"
		line = "#{arguments} "
		res_pre = ""
		
		ararg = Array.new
		ari = 0
		sql_limt = 72
		sql_limb = 72
		
		if (line =~ /^(\d+) (\d+) (.*)/)
			sql_limt = $1.to_i
			sql_limb = $2.to_i - 1
			line = $3
		elsif (line =~ /^(\d+) (.*)/)
			sql_limt = $1.to_i
			sql_limb = 0
			line = $2
		else
			sql_limt = 10
			sql_limb = 0
		end
		## Max value of calls ##
		if (sql_limt-sql_limb) > 20
			sql_limt = sql_limb + 20
			
		end
		
		if (line =~ /^lines (.*)/ || line =~ /^line (.*)/)
			sql_sel_count = "COUNT(*) AS cnt"
			res_pre = "#{res_pre}[12LINES]"
			line = $1
		elsif (line =~ /^char (.*)/ || line =~ /^chars (.*)/ || line =~ /^characters (.*)/)
			sql_sel_count = "SUM( LENGTH(message) ) AS cnt"
			res_pre = "#{res_pre}[12CHARACTERS]"
			line = $1
		elsif (line =~ /^words (.*)/ || line =~ /^word (.*)/)
			sql_sel_count = "SUM( LENGTH(message) - LENGTH(REPLACE(message, ' ', ''))+1) AS cnt"
			res_pre = "#{res_pre}[12WORDS]"
			line = $1
		else
			sql_sel_count = "SUM( LENGTH(message) - LENGTH(REPLACE(message, ' ', ''))+1) AS cnt"
			res_pre = "#{res_pre}[12WORDS]"
		end

		if( line == " " ) # Assume user wants top words today
			line = "-" # Adding unwanted character for any further if statements
			sql_where = "#{sql_where} AND `time` BETWEEN CONCAT(CURDATE(), ' 00:00:00') AND CONCAT(CURDATE(), ' 23:59:59')"
			res_pre = "#{res_pre}[12Today]"
		elsif( line == "- " ) # Assume he wants info about himself for today in current channel
			line = "-" # Adding unwanted character for any further if statements
			sql_where = "#{sql_where} AND `time` BETWEEN CONCAT(CURDATE(), ' 00:00:00') AND CONCAT(CURDATE(), ' 23:59:59')"

			req_chan = from
			chan_id = @config.chanhash[req_chan.downcase]
			sql_where = "#{sql_where} AND `from` = ?"
			ararg[ari] = chan_id
			ari += 1
			res_pre = "#{res_pre}[12#{from}][12Today]"
		elsif( line =~ /^today (.*)/ )
			line = $1
			sql_where = "#{sql_where} AND `time` BETWEEN CONCAT(CURDATE(), ' 00:00:00') AND CONCAT(CURDATE(), ' 23:59:59')"
			res_pre = "#{res_pre}[12Today]"
		elsif( line =~ /^yest (.*)/ )
			line = $1
			sql_where = "#{sql_where} AND `time` BETWEEN CONCAT(CURDATE() - INTERVAL 1 DAY, ' 00:00:00') AND CONCAT(CURDATE() - INTERVAL 1 DAY, ' 23:59:59')"
			res_pre = "#{res_pre}[12Yesterday]"
		elsif( line =~ /^24h (.*)/ )
			line = $1
			sql_where = "#{sql_where} AND `time` BETWEEN CONCAT(CURDATE() - INTERVAL 1 DAY, ' ', CURTIME()) AND CONCAT(CURDATE(), ' ', CURTIME())"
			res_pre = "#{res_pre}[12Past 24 hours]"
		elsif( line =~ /^week (.*)/ )
			line = $1
			sql_where = "#{sql_where} AND `time` BETWEEN CONCAT(CURDATE() - INTERVAL 1 WEEK, ' ', CURTIME()) AND CONCAT(CURDATE(), ' ', CURTIME())"
			res_pre = "#{res_pre}[12Past week]"
		elsif( line =~ /^month (.*)/ )
			line = $1
			sql_where = "#{sql_where} AND `time` BETWEEN CONCAT(CURDATE() - INTERVAL 1 MONTH, ' ', CURTIME()) AND CONCAT(CURDATE(), ' ', CURTIME())"
			res_pre = "#{res_pre}[12Last Month]"
		elsif( line =~ /^all (.*)/ )
			line = $1
			res_pre = "#{res_pre}[12Since 2012-06-19]"
		elsif( line =~ /-d (\d{4})-(\d{2})-(\d{2}) (\d{2}):(\d{2}):(\d{2}) (\d{4})-(\d{2})-(\d{2}) (\d{2}):(\d{2}):(\d{2}) (.*)/ )
			line = $13
			sql_where = "#{sql_where} AND `time` BETWEEN ? AND ?"
			ararg[ari] = "#{$1}-#{$2}-#{$3} #{$4}:#{$5}:#{$6}"
			ari += 1
			ararg[ari] = "#{$7}-#{$8}-#{$9} #{$10}:#{$11}:#{$12}"
			ari += 1
			res_pre = "#{res_pre}[12Between #{ararg[ari-2]} and #{ararg[ari-1]}]"
		else
			sql_where = "#{sql_where} AND `time` BETWEEN CONCAT(CURDATE(), ' 00:00:00') AND CONCAT(CURDATE(), ' 23:59:59')"
			res_pre = "#{res_pre}[12Today]"
		end
		
		if( line =~ /#(.+?) / )
			req_chan = "\##{$1}"
			#@irc.notice( nick, "-#{$1}-" )
			#@irc.message( from, "# #{req_chan}" )
			if(chan_id = @config.chanhash[req_chan.downcase])
				sql_where = "#{sql_where} AND `from` = ?"
				ararg[ari] = chan_id
				ari += 1
				res_pre = "#{res_pre}[12#{req_chan}]"
			else
				res_pre = "#{res_pre}[4Channel #{req_chan} Not Found][12All Channels]"
			end
		else
			res_pre = "#{res_pre}[12All Channels]"
		end
		
		if( line =~ /\$(.+?) / )
			if( line =~ /\$msg/ )
				sql_where = "#{sql_where} AND `type` = 1"
				res_pre = "#{res_pre}[12Messages]"
			elsif( line =~ /\$action/ )
				sql_where = "#{sql_where} AND `type` = 2"
				res_pre = "#{res_pre}[12Actions]"
			end
		end
		
		if (line =~ /-(s|ns|r|nr) "(.+)" /)
		
			#sql_sel = "COUNT( * ) FROM `logs`"
			#num_res = 0
			res_pre = "#{res_pre}[12SEARCH 6"
			sql_sel_count = "COUNT(*) AS cnt"
		
			if (line =~ /-s "(.+?)" /) ## Like Search ##
				res_pre = "#{res_pre}|LIKE|"
				sql_where = "#{sql_where} AND `message` LIKE ?"
				ararg[ari] = $1
				ari += 1
			end
			if (line =~ /-ns "(.+?)" /) ## Not Like Search ##
				res_pre = "#{res_pre}|NOT LIKE|"
				sql_where = "#{sql_where} AND `message` NOT LIKE ?"
				ararg[ari] = $1
				ari += 1
			end
			if (line =~ /-r "(.+?)" /) ## RegExp Search ##
				res_pre = "#{res_pre}|REGEXP|"
				sql_where = "#{sql_where} AND `message` REGEXP ?"
				ararg[ari] = $1
				ari += 1
			end
			if (line =~ /-nr "(.+?)" /) ## Not RegExp Search ##
				res_pre = "#{res_pre}|NOT REGEXP|"
				sql_where = "#{sql_where} AND `message` NOT REGEXP ?"
				ararg[ari] = $1
				ari += 1
			end
			res_pre = "#{res_pre} ]"
		end
		
		
		ararg[ari] = sql_limb
		ararg[ari+1] = sql_limt

		sql = "#{sql_select}, #{sql_sel_count} #{sql_from} #{sql_where} #{sql_post} LIMIT ?,?"
		if( from == "#testingbot" )
			@irc.message( from, "#{sql}" )
		end
		get_info = @config.my.prepare( sql )
		if( from == "#testingbot" )
			@irc.message( from, "#{ararg}" )
		end
		res_output = "#{res_pre} - "
		place = sql_limb + 1
		get_info.execute(*ararg).each do |row|
			res_output = "#{res_output}|#{place}|3 #{row[0]}(14#{row[1]}) "
			place += 1
		end
		if ( sql_limb == 0 )
			res_output = "[12Top#{sql_limt}]#{res_output}"
		else
			res_output = "[12Top #{sql_limb+1} to #{place-1}]#{res_output}"
		end
		#@output.good( "#{result[0]} characters in #{result[1]} words in #{result[2]} lines.\n" )
		@irc.message( from, res_output )
		get_info.close
		#res.free
	end
end
