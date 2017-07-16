# World Shapefile ISO 3166-1

World shapefile of ISO 3166-1 entities, based on Natural Earth 1:10m Cultural Vectors.

The R script loads the Natural Earth 1:10m Cultural Vectors "Admin 1 – States, Provinces" version 3.0.0, and aggregates entities by their ISO 3166-1 code, keeping the entities that have no ISO 3166-1 code attached as separated entities.

[Download](https://github.com/sdesabbata/world_shapefile_ISO3166-1/blob/master/world_iso_codes__from_ne_10m__20160105_v0_1_1.zip?raw=true) the zip file "world_iso_codes__from_ne_10m" that contains the output shapefile, which can be used for mapping. That does not currently includes coordinate reference system information -- please use WGS84.

NOTE: There are 12 ISO codes not reported in Natural Earth, and thus currently not aggregated in the world shapefile of ISO 3166-1 -- see "Missing ISO 3166-1 codes in NE 1:10m Admin1" issue.
