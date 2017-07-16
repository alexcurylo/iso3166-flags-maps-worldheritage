# by Stefano De Sabbata
# Department of Geography, University of Leicester
#
# version 0.1.1
#
# This script loads the Natural Earth Admin1 shapefile,
# dissolves the polygons of all Admin1 entities by ISO 3316-1 codes,
# thus creating one polygon for each ISO 3316-1 code.
#
# Admin1 entities in the Natural Earth dataset
# which have no reference to any ISO 3316-1 code
# are maintained as they are.
#
# Original data available at
# http://www.naturalearthdata.com/

### Part 0: Set up the working environment

# Load libraries
library(sp)
library(maptools)

# Set working directory
setwd("...")

# Load Natural Earth Admin1 shapefile
crs.wgs84 <- CRS("+proj=longlat +ellps=WGS84 +towgs84=0.000,0.000,0.000 +no_defs")
ne_data <- readShapePoly("ne_10m_admin_1_states_provinces/ne_10m_admin_1_states_provinces.shp", proj4string=crs.wgs84)


### Part 1: Create a layer of ISO 3316-1 codes polygons

# Fix missing ISO 3316-1 codes in Admin1
ne_data@data$iso_a2 <- as.character(ne_data@data$iso_a2)
ne_data@data[ which(ne_data@data$fips=="FG01") ,"iso_a2"] <- "GF"

# Select the Admin1 which are part of entities identified by ISO 3316-1 codes
admin1_iso <- ne_data
admin1_iso@data <- subset( admin1_iso@data, select = iso_a2 )
admin1_iso <- admin1_iso[admin1_iso@data$iso_a2!="-1",]

# Dissolve the polygons by ISO 3316-1 codes
admin1_iso_dissolved <- unionSpatialPolygons(admin1_iso, admin1_iso@data$iso_a2)

# List of ISO 3316-1 codes in the Natural Earth Admin1 shapefile
admin1_iso_list <- as.data.frame(unique(admin1_iso@data[admin1_iso@data$iso_a2!="-1",]))
colnames(admin1_iso_list) <- c("iso31661a2")

# Load further ISO 3316-1 codes information from CSV file
admin1_iso_info <- read.csv("iso_codes_info.csv", sep = ",", header = TRUE, dec = ".", quote = "", stringsAsFactors = FALSE, fileEncoding = "UTF-8", na.strings = "")

# Create the data frame for the entities in the Natural Earth Admin1 shapefile
admin1_iso_info <- merge(admin1_iso_list, admin1_iso_info, by.x="iso31661a2", by.y="iso31661a2", all.x=TRUE, all.y=FALSE)

# Combine the dissolved polygons and the data frame
iso_entities <- SpatialPolygonsDataFrame(admin1_iso_dissolved, admin1_iso_info, match.ID="iso31661a2")


### Part 2: Create a layer of the other entities

# Select the Admin1 which are not part of entities identified by ISO 3316-1 codes
admin1_no_iso <- ne_data
admin1_no_iso@data <- subset( admin1_no_iso@data, select = c(iso_a2,name))
colnames(admin1_no_iso@data) <- c("iso31661a2","name")
admin1_no_iso <- admin1_no_iso[admin1_no_iso@data$iso31661a2=="-1",]

# Add further columns as in the ISO 3316-1 codes data frame
admin1_no_iso@data["iso31661a3"] <- ""
admin1_no_iso@data["iso3166num"] <- ""
admin1_no_iso@data["region"] <- ""


### Part 3: Combine the layers and save

# Combine the two SpatialPolygonsDataFrame
iso_codes_plus_no_iso <- spRbind(iso_entities,admin1_no_iso)

# Write shapefile (this doesn't save the CRS)
writePolyShape(iso_codes_plus_no_iso, "world_iso_codes__from_ne_10m/world_iso_codes__from_ne_10m.shp")