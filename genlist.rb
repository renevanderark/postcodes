#!/usr/bin/ruby

require "./lookup"

total = ARGV[0] ? ARGV[0].to_f : 80486.0
offset = ARGV[2] ? ARGV[2].to_i : 0
is_open = ARGV[3] ? ARGV[3] : "open"
fails = 0
lastStreet = lastZip = lastPlace = nil
STDIN.each_with_index do |line, index|
	$stderr.puts "#{index} #{offset}"
	next unless index >= offset
	$stderr.puts "\n(#{'%0.2f' % ((index.to_f / total) * 100.0)}%)" if(index % 100 == 0)
	(place, zip, street) = line.split(",")
	zip.sub!(/[ A-Z]+$/, "")
	next if street =~ /Postbus/ || place =~ /Woonplaats/ || (lastStreet == street && lastPlace == place && lastZip == zip)
	geo = nil
	count = 0
	while((geo = LookUp.new({:place => place, :street => street, :zip => zip.sub(" ", ""), :source => is_open}).geo).nil? && count < 2) # :source => "open"
		count += 1
		sleep(0.05 * count.to_f)
	end

	if geo
		puts "#{place}, #{street}, #{zip}, #{geo[:lat]}, #{geo[:lon]}"
		$stdout.flush
		$stderr.print "."
		fails = 0
	else
		$stderr.print "x" 
		fails += 1
	end
	$stderr.flush
	if fails == 20
		$stderr.puts index
		break
	end

	lastPlace = place
	lastZip = zip
	lastStreet = street
end
