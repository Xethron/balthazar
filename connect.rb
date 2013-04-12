#!/usr/bin/env ruby

require 'timeout'

# Class to make and manage connection
class Connection
	def initialize( status, config, output )
		@status		= status
		@config		= config
		@output		= output
	end

	# Start connection
	def start
		@output.std( "Connecting ....................... " )

		sock = TCPSocket
		begin
			timeout( @config.connecttimeout ) do
				sock = TCPSocket.open( @config.server, @config.port )
			end
		rescue Timeout::Error
			@output.bad( "[NO]\n" )
			@output.debug( "Connection timeout.\n" )
			Process.exit
		rescue
			@output.bad( "[NO]\n" )
			@output.debug( "Error: " + $!.to_s + "\n" )
			Process.exit
		end
		@output.good( "[OK]\n" )

		# Kick off SSL
		if( @config.ssl && @status.ssl )
			@output.std( "Starting SSL ..................... " )

			begin
				ssl_context = OpenSSL::SSL::SSLContext.new

				if( @config.verifyssl )				
					ssl_context.verify_mode = OpenSSL::SSL::VERIFY_PEER
					ssl_context.ca_file = @config.rootcert
				else
					ssl_context.verify_mode = OpenSSL::SSL::VERIFY_NONE
				end
					ssl_sock = OpenSSL::SSL::SSLSocket.new(sock, ssl_context)
					ssl_sock.sync_close = true
					ssl_sock.connect

					if( ssl_sock.verify_result != 0 && @config.verifyssl )
						@output.bad( "[NO]\n" )
						@output.debug( getSSLerror( ssl_sock.verify_result ) + "\n" )
						Process.exit
					end

					@output.good( "[OK]\n" )
					return ssl_sock
			rescue OpenSSL::SSL::SSLError
				@output.bad( "[NO]\n" )
				@output.debug( getSSLerror( ssl_sock.verify_result ) + "\n" )
				Process.exit
			end
		else
			return sock
		end
	end

	# Function to make SSL error codes human readable
	def getSSLerror( errorcode )
		case errorcode
			when 0
				return "The operation was successful."
			when 2 
				return "Unable to get issuer certificate."
			when 3
				return "Unable to get certificate CRL."
			when 4
				return "Unable to decrypt certificate's signature."
			when 5
				return "Unable to decrypt CRL's signature."
			when 6
				return "Unable to decode issuer public key."
			when 7
				return "Certificate signature failure."
			when 8
				return "CRL signature failure."
			when 9
				return "Certificate is not yet valid."
			when 10
				return "Certificate has expired."
			when 11
				return "CRL is not yet valid."
			when 12
				return "CRL has expired."
			when 13
				return "Format error in certificate's notBefore field."
			when 15
				return "Format error in CRL's lastUpdate field."
			when 17
				return "Out of memory."
			when 18
				return "Self signed certificate."
			when 19
				return "Self signed certificate in certificate chain."
			when 20
				return "Unable to get local issuer certificate."
			when 21
				return "Unable to verify the first certificate."
			when 22
				return "Certificate chain too long."
			when 23
				return "Certificate revoked."
			when 24
				return "Invalid CA certificate."
			when 25
				return "Path length constraint exceeded."
			when 26
				return "Unsupported certificate purpose."
			when 27
				return "Certificate not trusted."
			when 28
				return "Certificate rejected."
			when 29
				return "Subject issuer mismatch."
			when 30
				return "Authority and subject key identifier mismatch."
			when 31
				return "Authority and issuer serial number mismatch."
			when 32
				return "Key usage does not include certificate signing."
			when 50
				return "Application verification failure."
			else
				return "Unknown error no: " + errorno.to_s
		end
	end
end
