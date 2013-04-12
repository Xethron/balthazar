#!/usr/bin/env ruby

# Plugin for online user help
class Help
	def initialize( status, config, output, irc, timer )
		@status		= status
		@config		= config
		@output		= output
		@irc		= irc
		@timer		= timer
	end

	def main( nick, user, host, from, msg, arguments, con )
		if( arguments.nil? || arguments.empty? )
			# General help
			tmp = [
				"Use 'help topic' for help on a specific topic.",
				"Topics:",
				"  commands                            - General bot commands",
				"  core                                - Help for core plugin",
				"  plugins                             - Help for plugins",
				" ",
				"Some plugins may also support help, in that case 'help pluginname'",
				"will send you the plugins help.",
				"A list of loaded plugins can be found with the 'loaded' command."
			]
		else
			# Specific help
			case arguments
			when "commands"
				tmp = [
					"Built in commands:",
					"  quit [message]              - Make bot quit IRC",
					"  load/unload [plugin]        - Load and unload plugins",
					"  reload [plugin]             - Reload plugin",
					"  loaded                      - List loaded plugins (public command)",
					"  available                   - List all available plugins (public command)"
				]
			when "core"
				tmp = [
					"Available commands:",
					"  message [to] [message]              - Send regulare message",
					"  action [to] [action]                - Send action",
					"  notice [to] [message]               - Send notice",
					"  raw [command]                       - Send raw command",
					"  join [channel]                      - Make bot join channel",
					"  part [channel]                      - Make bot part channel",
					"  topic [channe] [topic]              - Set topic for channel",
					"  mode [to] [mode] [subject]          - Set modes",
					"  op/deop [channel] [nick]            - Give/take chan op",
					"  hop/dehop [channel] [nick]          - Give/take chan half-op",
					"  voice/devoice [channel] [nick]      - Give/take voice",
					"  kick [channel] [nick] [reason]      - Kick user from channel",
					"  ban/unban [channel] [host]          - Ban/unban host",
					"  timeban [channel] [host] [seconds]  - Set ban that's automatically removed",
					"  version                             - Check bot version (public command)",
					"  uptime                              - Check bot uptime (public command)",
					"  nick [nickname]                     - Change bot nickname"
				]

			when "plugins"
				tmp = [
					"Help for plugins:",
					"  To call the main function of a plugin, use the plugin name as a command.",
					"  To call a function within the plugin, use the plugin name followed by the",
					"  function name as a command, separated by a space.",
					"",
					"Examples:",
					"  help                        - Call 'help' plugins main function.",
					"  help plugins                - Call 'plugins' function from 'help' plugin.",
					"  plugin func [args]          - Call 'func' from 'plugin' with 'args' as input."
				]
			when "topic"
				tmp = [ "Don't be a smartass." ]
			else
				# See if there is a plugin by that name which supports help
				pluginname = arguments.gsub( /[^a-zA-Z0-9 -]/, "" ).downcase
				if( @status.checkplugin( pluginname ) )
					# Get plugin
					plugin = @status.getplugin( pluginname )

					# See if the plugin support help.
					if( plugin.respond_to?( "help" ) )
						plugin.help( nick, user, host, from, msg, arguments, con )
						tmp = [ "End of help from #{pluginname}." ]
					else
						tmp = [ "Plugin #{pluginname} is loaded, but doesn't support help." ]
					end
				else
					tmp = [ "No help for #{arguments}." ]
				end
			end
		end

		# Print out help
		tmp.each do |line|
			if( con )
				@output.c( line + "\n" )
			else
				@irc.notice( nick, line )
			end
		end
		tmp = nil
	end
end
