#!/usr/bin/env ruby

# Class to handle user commands
class Commands
	alias_method :loadfile, :load
	def initialize( status, config, output, irc, timer, console = 0 )
		@status		= status
		@config		= config
		@output		= output
		@irc		= irc
		@timer		= timer
		@console	= console

		# List of protected commands for plugins
		@protected	= [ "kicked", "noticed", "messaged", "joined", "parted", "quited" ]

		# Hashtables to keep flood statistics
		@floodlevel	= {}
		@lastcmd	= {}
	end

	# Shorthands
	def con
		return( @console == 1 )
	end

	def cmc
		return @config.command
	end

	def sanitize( input, downcase = 0 )
		input.gsub!( /[^a-zA-Z0-9 -]/, "" )
		if( downcase == 1 )
			input.downcase!
		end
	end

	# Inital command parsing & function calling
	def process( nick, user, host, from, msg, skipflood = false )

		# Do command throttling if desireable and threading allows it
		if( @status.threads && @config.threads && @config.antiflood && !con && !skipflood )
			# Determine threshold
			if( @floodlevel[ user+host ].nil? || @floodlevel[ user+host ] < 1 )
				@floodlevel[ user+host ] = 0
				threshold = @config.floodtime
			else
				threshold = @config.floodtime * @floodlevel[ user+host ]
			end

			# Check if time between now and the last command is less than trigger time
			if( @lastcmd[ user+host ].nil? )
				@lastcmd[ user+host ] = Time.new - threshold
			end

			if( ( Time.new - @lastcmd[ user+host ] ) < threshold )
				if( @floodlevel[ user+host ] > 4 )
					# Drop request
					@lastcmd[ user+host ] = Time.new
					Thread.exit
				else
					# Delay thread
					@floodlevel[ user+host ] += 1
					@irc.notice( nick, "Delaying your command by " + threshold.to_s + " seconds. If too many requests are sent in a short time, they may be dropped.", true )
					@lastcmd[ user+host ] = Time.new
					sleep( threshold )
				end
			else
				@lastcmd[ user+host ] = Time.new

				if( @floodlevel[ user+host ].nil? || @floodlevel[ user+host ] < 1 )
					@floodlevel[ user+host ] == 0
				else
					@floodlevel[ user+host ] -= 1
				end
			end
		end

		cmd, rest = msg.split(' ', 2)

		if( !cmd.nil? && !cmd.empty? )
			sanitize( cmd, 1 )

			begin
				# Calls to local methods
				eval( "self.#{cmd}( nick, user, host, from, msg )" )
			rescue NoMethodError
				# See if we have a plugin loaded by this name.
				if( @status.checkplugin( cmd ) )
					# Get plugin
					plugin = @status.getplugin( cmd )

					# Parse function call
					if( !rest.nil? && !rest.empty? )
							function, arguments = rest.split(' ', 2)
							sanitize( function )

						# See if such a method exists in this plugin and isn't protected, if so, call it
						if( plugin.respond_to?( function ) && !@protected.include?( function ) )
							eval( "plugin.#{function}( nick, user, host, from, msg, arguments, con )" )
						else
							# Call default method with the function as argument
							if( plugin.respond_to?( "main" ) )
								plugin.main( nick, user, host, from, msg, rest, con )
							end
						end
					else
						# Call default method
						if( plugin.respond_to?( "main" ) )
							plugin.main( nick, user, host, from, msg, rest, con )
						end
					end
				else
					if( cmd != "core" )
						# Try to call as command from core plugin
						process(nick, user, host, from, "core " + msg , true )
					end
				end
			end
		end
	end

	# Quit command
	def quit( nick, user, host, from, msg )
		if( @config.auth( user, host, con ) )
			if( con )		
				@output.cbad( "This will also stop the bot, are you sure? [y/N]: " )
				STDOUT.flush
				ans = STDIN.gets.chomp
			end
			if( ans =~ /^y$/i || !con )
				cmd, message = msg.split( ' ', 2 )

				if( message == nil )
					@irc.quit( @config.nick + " was instructed to quit.", true )
				else
					@irc.quit( message, true )
				end

				@output.std( "Received quit command.\n" )

				@status.reconnect( 0 )
				@irc.disconnect
				Process.exit
			else
				if( con )
					@output.cinfo( "Continuing" )
				end
			end
		end
	end

	# Load modules
	def load( nick, user, host, from, msg, auto = false )
		if( @config.auth( user, host, con ) )
			cmd, plugin = msg.split( ' ', 2 )
			if( plugin != nil )
				# Clean variable
				sanitize( plugin, 1 )

				# Check if plugin isn't loaded already
				if( !@status.checkplugin( plugin ) )
					# Check file exists
					if( FileTest.file?( @config.plugindir + "/" + plugin + ".rb" ) )

						# Check syntax & load
						begin
							# Try to load the plugin
							eval( "loadfile './#{@config.plugindir}/#{plugin}.rb'" )
							@output.debug( "Load was successful.\n" )

							object = nil
							# Try to create an object
							eval( "object = #{plugin.capitalize}.new( @status, @config, @output, @irc, @timer )" )
							@output.debug( "Object was created.\n" )

							# Push to @plugins
							eval( "@status.addplugin( plugin, object )" )
							@output.debug( "Object was pushed to plugin hash.\n" )

							if( con )
								if( !auto )
									@output.cgood( "Plugin " + plugin + " loaded.\n" )
								end
							else
								@irc.notice( nick, "Plugin " + plugin + " loaded." )
							end
						rescue Exception => e
							if( con )
								@output.cbad( "Failed to load plugin:\n" )
								@output.cinfo( e.to_s + "\n" )
							else
								@irc.notice( nick, "Failed to load plugin: " + e.to_s )
							end
						end
					else
						# Not found
						if( con )
							@output.cbad( "Plugin " + plugin + " not found.\n" )
						else
							@irc.notice( nick, "Plugin " + plugin + " not found." )
						end
					end
				else
					if( con )
						@output.cbad( "Plugin " + plugin + " is already loaded.\n" )
					else
						@irc.notice( nick, "Plugin " + plugin + " is already loaded." )
					end
				end
			else
				if( con )
					@output.info( "Usage: " + cmc + "load plugin" )
				else
					@irc.notice( nick, "Usage: " + cmc + "load plugin" )
				end				
			end
		end
	end

	# Unload module
	def unload( nick, user, host, from, msg )
		if( @config.auth( user, host, con ) )
			cmd, plugin = msg.split( ' ', 2 )
			if( plugin != nil )
				# Clean variable
				sanitize( plugin, 1 )

				# Check if plugin is loaded
				if( @status.checkplugin( plugin ) )
					begin
						# Remove @plugins
						eval( "@status.delplugin( plugin )" )
						@output.debug( "Object was removed from plugin hash.\n" )

						if( con )
							@output.cgood( "Plugin " + plugin + " unloaded.\n" )
						else
							@irc.notice( nick, "Plugin " + plugin + " unloaded." )
						end
					rescue Exception => e
						if( con )
							@output.cbad( "Failed to unload plugin:\n" )
							@output.cinfo( e.to_s + "\n" )
						else
							@irc.notice( nick, "Failed to unload plugin: " + e.to_s )
						end
					end
				else
					if( con )
						@output.cbad( "Plugin " + plugin + " is not loaded.\n" )
					else
						@irc.notice( nick, "Plugin " + plugin + " is not loaded." )
					end
				end
			else
				if( con )
					@output.info( "Usage: " + cmc + "unload plugin" )
				else
					@irc.notice( nick, "Usage: " + cmc + "unload plugin" )
				end				
			end
		end
	end

	# Meta function to reload modules
	def reload( nick, user, host, from, msg )
		unload( nick, user, host, from, msg )
		load( nick, user, host, from, msg )
	end

	# Meta funcion to load autoload modules
	def autoload( nick = nil, user = nil, host = nil, from = nil, msg = nil )
		@config.autoload.each do |mod|
			load( nil, nil, nil, nil, "dummy " + mod, true )
		end
	end

	# Function to get list of loaded modules
	def loaded( nick, user, host, from, msg )
		if( con )
			@output.c( "Loaded plugins: " )
			@status.plugins.each_key do |plugin_name|
				@output.c( plugin_name + " " )
			end
			@output.c( "\n" )
		else
			tmp_list = ""
			@status.plugins.each_key do |plugin_name|
				tmp_list = tmp_list +  plugin_name + " "
			end

			@irc.notice( nick, "Loaded plugins: " + tmp_list )
			tmp_list = nil
		end
	end

	# Function to list available modules
	def available( nick, user, host, from, msg )
		contents = Dir.entries("./" + @config.plugindir + "/" )
		plugs = Array.new
		contents.entries.each do |file|
			if( file =~ /\.rb$/i )
				file.gsub!( /\.rb$/i, "" )
				plugs.push( file )
			end
		end

		if( con )
			@output.c( "Available plugins: " )
			plugs.each do |p|
				@output.c( p + " " )
			end
			@output.c( "\n" )
		else
			output = "Available plugins: "
			plugs.each do |p|
				output = output + p + " "
			end
			@irc.notice( nick, output )
			output = nil
		end
		contents = nil
		plugins = nil
	end
end
