#!/usr/bin/env python3

'''
Given a TIFF image of an agarose gel and a CSV identifying the lanes, 
use ImageMagick to create an image with sample IDs annotated 
above (or at least vaguely near) each lane. 

Usage: ./gel-labeler.py my_gel.tif ids_for_my_gel.csv my_labeled_gel.jpg

Input image must be TIFF or at least have the same EXIF tag names. 
Output image need not be JPEG -- ImageMagick will produce any format you specify.

NOTE: This script makes no attempt to confirm the placement of the lanes, 
it just assumes they're evenly spread across the image area. 
It may well miss completely, especially for poorly-aligned gels. 
Probably don't expect the output to be publication-quality on the first try.

Requires ImageMagick compiled with TIFF support (-with-libtiff), 
and the exifread module (available through pip, e.g. $(pip install exifread)).
'''

from sys import argv
import csv, exifread, subprocess

# Examine TIFF image dimensions by checking EXIF tags.
img = open(argv[1], 'rb')
tags = exifread.process_file(img, details=False)
width = tags['Image ImageWidth'].values[0]
height = tags['Image ImageLength'].values[0]
img.close()

# Read in sample IDs for each lane from CSV.
rows = []
lanes = []
ids = []
with open(argv[2], 'r') as lanefile:
    laneiter = csv.DictReader(lanefile, delimiter=',', skipinitialspace=True)
    for lane in laneiter:
        rows.append(int(lane['row']))    
        lanes.append(int(lane['lane']))
        ids.append(lane['id'])


# Calculate probabable lane placement for number of lanes and rows in CSV.
# Assumes image is cropped ~1 lanewidth from left edge of lane 1 
# and ~1.5 lanewidths from top of row 1 wells, which seems reasonable for 
# 8-lane minigels. Check if using on other shapes!
hspace = width / (max(lanes) + 1.0)
vspace = (height - 1.5*hspace) / max(rows) 


# Construct a shell command to do the actual conversion. First the invariants...
#TODO: consider more careful gamma adjustment--still pretty dark on my screen
cmd = [
    "convert", 
    argv[1], 
    "-auto-level", 
    "-fill", "white", 
    "-pointsize", "18"]

# ...then an annotation for each lane...
for i in range(len(lanes)):
    curx = hspace*lanes[i]
    cury = 1.5*hspace + ((rows[i]-1) * vspace)
    cmd = cmd + [
        "-annotate", 
        "-18x+%i+%i" % (curx, cury), #-18 = degrees text rotation
        "%s" % ids[i]
    ]

# ...and the name of the output file. 
cmd.append(argv[3])

subprocess.call(cmd)
