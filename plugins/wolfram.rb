#!/usr/bin/env ruby

# Query Wolfram Alpha

require "rubygems"
require "nokogiri"
require 'open-uri'
require 'cgi'
class Wolfram

	# This method is called when the plugin is first loaded
	def initialize( status, config, output, irc, timer )
		@status		= status
		@config		= config
		@output		= output
		@irc		= irc
		@timer		= timer
	end

	def main( nick, user, host, from, msg, arguments, con )
		arguments = CGI.escape(arguments)
		url = "http://api.wolframalpha.com/v2/query?input=#{arguments}&format=plaintext&appid=######-##########"
		doc = Nokogiri::XML(open(url).read)
		pods = doc.xpath('//pod')
		text = doc.xpath('//pod//subpod//plaintext')
		@irc.message( from, "#{pods[0]["title"]}: #{text[0].content.gsub("\n", " ").gsub(" |", ":")}" )
		@irc.message( from, "#{pods[1]["title"]}: #{text[1].content.gsub("\n", " ").gsub(" |", ":")}" )
	end
end
