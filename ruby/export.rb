# This script gets all the OSM changes from a given bounding box over time.
#
# The way it does, theoretically (I haven't finished) is by:
#  1) Set dates to figure out data (should start at beginning of time)
#  2) Define Area (in a .poly file)
#  3) Run Loop for each day:
#     1) Download the day's change file
#     2) Apply the changefile to the data file (which will just have osm headers to start) and also cut out the poly again (see hot-export)
#     3) Derive new changeset file between this file and the previous day's
#     4) Use the new changeset file to determine new and deleted objects in the area.

# I guess if doing for Indo you could create an Indo .osc file at the start

# http://planet.openstreetmap.org/cc-by-sa/history/
# http://wiki.openstreetmap.org/wiki/Planet.osm/diffs
# http://wiki.openstreetmap.org/wiki/Osmosis#Detailed_Usage

#  1) Sort the OSM files
#	osmosis --read-xml file="output_data3.osm" --sort type="TypeThenId" --write-xml file="data-sorted3.osm"
#  2) Compare them:
#   osmosis --rx data-sorted3.osm --rx data-sorted2.osm --dc --wxc hmm4

# Need a bounding polygon of the area
# Need a history of changefiles

require 'date'
require 'fileutils'

# Download osc changefiles from OSM server and put into a directory
#  The names are changed to format year-mmdd-mmdd.osc.gz - the two days represent
#  the 24 hour period the changes occurred in
# Change these constants as required:
OSC_DIR = "osc"
START_DATE = Date.new(2005,4,9)
END_DATE = START_DATE + 10
UNZIP = false
def getOSC
  FileUtils.rm_rf(OSC_DIR)
  FileUtils.mkdir(OSC_DIR)
  for d in START_DATE..END_DATE
    filename = "#{d.strftime('%m%d')}-#{(d+1).strftime('%m%d')}.osc.gz"
    system("wget http://planet.openstreetmap.org/cc-by-sa/history/#{d.year}/#{filename}")
    system("mv #{filename} #{OSC_DIR}/#{d.year}-#{filename}")
    if UNZIP
      system("gunzip #{OSC_DIR}/#{d.year}-#{filename}")
    end
  end
end

# Process a directory full of osc changefiles to build an osm file
OSM_DIR = "osm"
OSM_FILE = "#{OSM_DIR}/uk.txt"
POLY = "poly/great-britain.poly"
def processOSC
  FileUtils.rm_rf(OSM_DIR)
  FileUtils.mkdir(OSM_DIR)
  FileUtils.touch(OSM_FILE)
  File.open(OSM_FILE, 'w') {|f| f.write("<?xml version='1.0' encoding='UTF-8'?>
                                         <osm version='0.6' generator='Osmosis 0.40.1'>
                                         </osm>") }
  Dir.entries(OSC_DIR).sort.each do |file|
    next if file == '.' or file == '..'
    system("cp #{OSM_FILE} temp.osm")
    system("osmosis --rxc #{OSC_DIR}/#{file} --rx temp.osm --ac --bp file=#{POLY} clipIncompleteEntities=true --wx #{OSM_FILE}")
    system("rm temp.osm")

  end
end


getOSC
processOSC

