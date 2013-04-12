#!/usr/bin/env ruby

# Plugin was used to test new consepts.
# Currently houses a concept to extract smileys from text and check if words are English/Afrikaans/Spelling error.
# This was going to be the next feature implamented. Help word counting by splitting up words accurately.
# Will be able to see what language is spoken most by whome in every channel.
# Also what words/smileys are used the most, and who uses which words/smileys the most.
# Also creating a custom dictionary for chat slang, and then spel check users typing, sending them a notice when they have a mistake with recommended fixes.

# Input sanitation is done by wrapper.

# Calling actions from the DB
class Dev
	
	# This method is called when the plugin is first loaded
	def initialize( status, config, output, irc, timer )
		@status		= status
		@config		= config
		@output		= output
		@irc		= irc
		@timer		= timer
		@whois		= status.getplugin( "whois" )
		
		@words		= config.wordhash
		@user_words	= Hash.new
	end
	
	# Generic function that can be called by any user
	def gwi( nick, user, host, from, msg, arguments, con )
		#@irc.notice( nick, "Loading Whois..." )
		mywhois = @whois.get( arguments )
		@irc.notice( nick, "#{mywhois}" )
	end
	
	def gwords( nick, user, host, from, msg, arguments, con )
		if (arguments.nil? || arguments.empty?)
			@irc.notice( nick, "WORDS: - #{@words}" )
		else
			@irc.notice( nick, "WORDS: - #{@words[arguments]}" )
		end
	end
	
	def main( nick, user, host, from, msg, arguments, con )
		message = arguments
		if( message =~ /^\001ACTION (.+)/ )
			msg_type = "2"
			message = $1
		else
			msg_type = "1"
		end
		
		smileys = message.scan(/([>]?[:;8xXB][-]?[)(dDoO0S$PpqcXx*|\\\/]|[:]['][(]|[Dq][:]|d-_-b|\b[0oO][_\.]?[0oO]\b|[\\\/]?[0Oo][\\\/]|[\\\/][0Oo]|<[\\\/]?3)/)#
		
		words = message.gsub(/([>]?[:;8xXB][-]?[)(dDoO0S$PpqcXx*|\\\/]|[:]['][(]|[Dq][:]|d-_-b|\b[0oO][_\.]?[0oO]\b|[\\\/]?[0Oo][\\\/]|[\\\/][0Oo]|<[\\\/]?3)/, "").split(/[^a-zA-Z0-9'-]/).reject(&:empty?)#
		
		@irc.message( from, "  SMILEYS: |  #{smileys.join("  |  ")}  | WORDS: | #{words.join("  |  ")}" ) 
		words.each do |word|
			word.downcase!
			if (!@words[word])
				lang = 0
				speller_af = Aspell.new("af")
				speller_af.set_option("ignore-case", "true")
				speller_af.suggestion_mode = Aspell::NORMAL
				if !speller_af.check(word) 
					suggest_af = speller_af.suggest(word)
				else
					lang += 1
				end
				speller_en = Aspell.new("en")
				speller_en.set_option("ignore-case", "true")
				speller_en.suggestion_mode = Aspell::NORMAL
				if !speller_en.check(word) 
					suggest_en = speller_en.suggest(word)
				else
					lang += 2
				end
				if lang != 0
					@words[word] = Array.new
					@words[word][1] = lang
					@words[word][2] = 0
				else
					@irc.notice( nick , "#{suggest_en}" )
				end
			end
			if (@words[word])
				@words[word][2] += 1
				if (!@user_words[nick.downcase])
					@user_words[nick.downcase] = Hash.new
					@user_words[nick.downcase][word] = 1
				elsif (@user_words[nick.downcase][word])
					@user_words[nick.downcase][word] += 1
				else
					@user_words[nick.downcase][word] = 1
				end
			end
		end		
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
