#!/usr/bin/env ruby

# Class used to send output to terminal
class Output
	def initialize( status )
		@status		= status

		@RED		= "\033[31m";
		@GREEN		= "\033[32m";
		@YELLOW		= "\033[33m";
		@BLUE		= "\033[34m";
		@END		= "\033[0m";
	end

	# Standard output
	def std( string )
		if( @status.output )
				$stdout.print( string )
		end
	end

	def info( string )
		if( @status.output )
			if( @status.colour )
				std( @YELLOW + string + @END )
			else
				std( string )
			end
		end
	end

	def special( string )
		if( @status.output )
			if( @status.colour )
				std( @BLUE + string + @END )
			else
				std( string )
			end
		end
	end

	def good( string )
		if( @status.output )
			if( @status.colour )
				std( @GREEN + string + @END )
			else
				std( string )
			end
		end
	end

	def bad( string )
		if( @status.output )
			if( @status.colour )
				std( @RED + string + @END )
			else
				std( string )
			end
		end
	end

	# Debug output
	def debug( string )
		if( @status.debug >= 1 )
			std( string )
		end
	end

	def debug_extra( string )
		if( @status.debug >= 2 )
			std( string )
		end
	end

	# Interactive console output
	def c( string )
		$stdout.print(string)
	end

	def cinfo( string )
		if( @status.colour )
			puts( @YELLOW + string + @END )
		else
			puts( string )
		end
	end

	def cbad( string )
		if( @status.colour )
			$stdout.print( @RED + string + @END )
		else
			$stdout.print( string )
		end
	end

	def cgood( string )
		if( @status.colour )
			$stdout.print( @GREEN + string + @END )
		else
			$stdout.print( string )
		end
	end

	def cspecial( string )
		if( @status.colour )
			puts( @BLUE + string + @END )
		else
			puts( string )
		end
	end
end
