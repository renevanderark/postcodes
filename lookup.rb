#!/usr/bin/ruby1.8

require "rubygems"
require "simple_get_response"
require "json"
require "cgi"


class LookUp
	attr_accessor :place, :street, :zip, :offset, :limit, :source
	def initialize(opts)
		self.place = opts[:place]
		self.zip = opts[:zip]
		self.street = opts[:street]
		self.limit = opts[:limit] || "1"
		self.offset = opts[:offset] || "1"
		self.source = opts[:source]
	end

	def geo
		if self.source == "open"
			url = "http://nominatim.openstreetmap.org/search?format=json&q=#{CGI.escape([street,zip.sub(/[ A-Z]+$/, ""),place].reject{|x| x== ""}.join(" "))}+nederland&countycodes=nl&addressdetails=1"
			get = SimpleGetResponse.new(url)
			return nil unless get.success?
			begin
				data = JSON.parse(get.body)
			rescue 
				return nil
			end
			return nil if data.length == 0
			return {:lon => data[0]["lon"], :lat => data[0]["lat"]}
		else
			get = SimpleGetResponse.new("http://maps.google.com/maps/geo?q=#{CGI.escape([street,zip,place].reject{|x| x== ""}.join(" "))}+nederland&output=json&oe=utf8&sensor=false&key=yourKey")
			data = JSON.parse(get.body)
			lon = lat = addr = nil
		 	(lon, lat) = data["Placemark"][0]["Point"]["coordinates"] if data["Placemark"] && data["Placemark"].length > 0 && data["Placemark"][0]["Point"]
			addr = data["Placemark"][0]["address"] if data["Placemark"] && data["Placemark"].length > 0 

			return {:lon => lon, :lat => lat, :addr => addr} if lon && lat
			get = SimpleGetResponse.new("http://maps.google.com/maps/geo?q=#{CGI.escape(place)}&output=json&oe=utf8&sensor=false&key=yourKey")
			data = JSON.parse(get.body)
			lon = lat = addr = nil
		 	(lon, lat) = data["Placemark"][0]["Point"]["coordinates"] if data["Placemark"] && data["Placemark"].length > 0 && data["Placemark"][0]["Point"]
			addr = data["Placemark"][0]["address"] if data["Placemark"] && data["Placemark"].length > 0 
			return {:lon => lon, :lat => lat, :addr => addr} if lon && lat
		end
	end

end
