#!/usr/bin/env ruby

# Load support files
require './config.rb'
require './output.rb'
require './startup.rb'
require './status.rb'
require './argparser.rb'
require './connect.rb'
require './timer.rb'
require './irc.rb'
require './ircparser.rb'
require './console.rb'

# Create support objects
status	= Status.new
output	= Output.new( status )
config	= Configuration.new( status, output )

# Process commandline options
parser	= ArgumentParser.new( status, config, output, $0 )
parser.parse( ARGV )
parser = nil

# Display banner
output.special( "Starting " + config.version + "\n\n" );

# Check for libraries
startup	= Startup.new( status, config, output )

startup.checksocket
startup.checkopenssl
startup.checkthreads
startup.checkoutputqueuing
startup.checkdirectoryplugins
startup.checkdirectorydata

startup = nil

# Show configuration, if desired.
config.show

# Main connect-parse loop
while status.reconnect do

	# Start connection
	socket = Connection.new( status, config, output ).start
	irc = IRC.new( status, config, output, socket )

	# Catch Ctrl-C
	Signal.trap( 'INT' ) do
		Signal.trap( 'INT', 'DEFAULT' )
		irc.quit( "Caught interrupt, quiting." )
		output.std( "Caught interrupt, quiting.\n" )
		status.reconnect( 0 )
		Process.exit
	end
	# Create timer object for later use
	timer = Timer.new( status, config, output, irc )

	# Create user input parser
	if( status.console )
		Console.new( status, config, output, irc, timer ).start
	end

	# Start parsing IRC
	parser = IRCParser.new( status, config, output, irc, timer ).start
end
