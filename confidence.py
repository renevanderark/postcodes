#!/usr/bin/python

from sys import stdin
from math import sqrt

latlons = []
lats = []
lons = []
lines = []
for line in stdin.readlines():
	(zipc,street,place,lat,lon) = line.strip().split(",")
	if(lat != "" and lon != ""):
		latlons.append((float(lat), float(lon)))
		lats.append(float(lat))
		lons.append(float(lon))
		lines.append(line)

center = (sum(lats) / len(lats), sum(lons) / len(lons))
euclids_from_center = [sqrt(((ll[0]-center[0])**2) + ((ll[1] - center[1])**2)) for ll in latlons]
mean = sum(euclids_from_center) / len(euclids_from_center)
sigma = sqrt(sum([(distance - mean)**2 for distance in euclids_from_center]) / len(euclids_from_center))

if(sigma == 0.0):
	for line in lines:
		print line.strip() + ",TRUSTED,Z=0.0"
else:
	Zs = [(distance - mean) / sigma for distance in euclids_from_center]
	for i in range(len(Zs)):
		if(Zs[i] > 2.0 or Zs[i] < -2.0):
			print lines[i].strip() + ",RECHECK POSITION,Z=" + str(Zs[i])
		else:
			print lines[i].strip() + ",TRUSTED,Z=" + str(Zs[i])

