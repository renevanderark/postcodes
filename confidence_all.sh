#!/bin/bash

FILES=$1/*
for f in $FILES
do
	echo "$f" 1>&2
	./confidence.py < $f > $2/$f
done
