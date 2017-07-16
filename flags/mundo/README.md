mundo-flags
===========

A collection of flags for countries defined in ISO 3166-1, part of the ISO 3166 
standard published by the [International Organization for Standardization (ISO)][1].


Scope
-----

The scope of this collection is limited only to the flags of countries listed 
in the current edition of ISO 3166-1.


Countries without a flag
------------------------

A place holder image is generated for countries without a flag. The place 
holder image consisted of the ISO 3166-1 alpha-2 code on a gray rectangular 
background.


Contributing
------------

If you identify an error please submit a new issue or open a pull request.

Many of the flags in this collection were obtained either from the 
[Wikimedia Commons Flag project][3] or [OpenClipart.org][4]. If you are 
creating or modifying artwork please consider submitting to these collections 
in the first instance, before submitting an issue to have it incorporated in 
this collection.


Why this project?
-----------------

There are a number of other public domain flag collections available, many of 
them more extensive than this collection, such as:

* [Wikimedia Commons Flag project][3]
* [OpenClipart.org][4]
* [xrmap flags collection][5]

The objective of this project is to produce a up-to-date and organised 
collection of sovereign flags for ISO 3166-1 countries that developers may 
easily incorporate into their projects without resorting to the use of web 
scrapers.


Files and directories
---------------------

* svg/

    Directory containing flag images in SVG format. File names follow this 
    format: [ISO 3166-1 alpha-2 code (lowercase)].svg For example: nz.svg, 
    gb.svg.

* check

    Script for validating the flag collection against the official list of 
    ISO 3166-1 countries.

* flags.csv

    List of ISO 3166-1 country codes along with the flag file name, and the 
    original file source.

* iso3166-1_en.csv

    [Official list of ISO 3166-1 countries][2]. As the publicly available CSV 
    and XML files are not version controlled please refer to different versions 
    by the date("YYYY-mm-dd") of download from the ISO website.

* LICENCE

    Licence information.

* Makefile

    Example makefile for converting SVG images to raster formats.

* placeholder.txt

    List of countries for which a placeholder image was generated.

* README.md

    This file.

* scraper

    Web scraper used to download the original set of flags from 
    [Wikimedia Commons Flag project][3]


[1]: http://www.iso.org/
[2]: http://www.iso.org/iso/country_codes.htm
[3]: http://commons.wikimedia.org/wiki/Commons:WikiProject_Flags
[4]: http://openclipart.org/
[5]: ftp://ftp.ac-grenoble.fr/ge/geosciences/xrmap/data/

