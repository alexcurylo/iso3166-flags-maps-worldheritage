#==============================================================================
# Example makefile for converting svg to raster formats
#
# Author: Seth Fischer
#
# Before running make the approprate output directories must be manually 
# created. e.g. mkdir output output/16x16 output/x54
#==============================================================================

# source directory
SRC_DIR := ./svg/

# output directory
OUTPUT_DIR := ./output/


# flag dependencies
FLAGS_SRC := $(wildcard $(SRC_DIR)*.svg)

# targets for flags 16x16 png padded with transparent background
FLAGS_16x16 := ${FLAGS_SRC:$(SRC_DIR)%.svg=$(OUTPUT_DIR)16x16/%.png}
# targets for flags 54 high
FLAGS_x54 := ${FLAGS_SRC:$(SRC_DIR)%.svg=$(OUTPUT_DIR)x54/%.png}

.PHONY	:	all
all	:	$(FLAGS_16x16) $(FLAGS_x54)

# flags 16x16 png padded with transparent background
$(OUTPUT_DIR)16x16/%.png	:	$(SRC_DIR)%.svg
	convert SVG:$^ -resize 16x16 -background transparent -gravity center -extent 16x16 $@

# flags 54 high png
$(OUTPUT_DIR)x54/%.png	:	$(SRC_DIR)%.svg
	convert SVG:$^ -resize x54 $@

