#!/usr/bin/ruby1.8

require "rubygems"
require "simple_get_response"
require "json"
require "hpricot"
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

	def articles
		docs = []
		get = SimpleGetResponse.new("http://jsru.kb.nl/sru?query=%22#{CGI.escape(street)}%22%20AND%20%22#{CGI.escape(place)}%22&x-collection=DDD&recordSchema=ddd&maximumRecords=#{limit}&startRecord=#{offset}")
		if get.success?
			doc = Hpricot.XML(get.body)
			(doc/'srw:recordData').each do |node|
				base_doc = {"words" => %("#{place}" "#{street}")}
				if (node/'dc:type').length > 0 # && ((node/'dc:type').first.innerText == "illustratie met onderschrift" || (node/'dc:type').first.innerText == "artikel")
					return false unless ((node/'dc:type').first.innerText == "illustratie met onderschrift" || (node/'dc:type').first.innerText == "artikel")
					base_doc["editie"] = (node/'ddd:papertitle').first.innerText
					base_doc["datum"] = (node/'dc:date').first.innerText
					(node/'ddd:metadataKey').map{|n| n.innerText}.each do |url|
						get1 = SimpleGetResponse.new(url + ":" + "ocr")
						if get1.success?
							doc1 = Hpricot.XML(get1.body)
							base_doc["title"] = (doc1/'title').first.innerText
							base_doc["ocr"] = ("<p>" + (doc1/'p').map{|p| p.innerText}.join("</p><p>") + "</p>").downcase
							base_doc["ocr"].gsub!(street.downcase, "<b>#{street}</b>")
							base_doc["ocr"].gsub!(place.downcase, "<b>#{place}</b>")
						end
						get4 = SimpleGetResponse.new(url.sub(/:[^:]+$/, ""))
						if get4.success?
							didl = Hpricot.XML(get4.body)
							article_urn = url.sub(/[^\=]+\=/, "")
							article_resource = (didl/'//didl:Item').select{|i| i.attributes["ddd:article_id"] == article_urn}.first
							
							zone_nodes = (article_resource/'//dcx:area')
							base_doc["areas"] = []
							zone_nodes.each do |z| 
								base_doc["areas"] << {
									"x" => z.attributes["hpos"].to_i,
									"y" => z.attributes["vpos"].to_i - 5,
									"w" => z.attributes["width"].to_i,
									"h" => z.attributes["height"].to_i + 10
								}
							end
							base_doc["image"] = article_resource.attributes["dc:identifier"].sub(/:[^:]+$/, ":image")
							base_doc["_id"] = article_resource.attributes["dc:identifier"]
						end
					end

				end
				docs << base_doc
			end
		end
		return docs
	end
end
