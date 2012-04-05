Who is the Middle Class?
----

An interractive viz exploring this question.

----

*Notes*

Generally see the Cakefile for instructions - what isn't automated is documented therein.

Group the data by State by income/sex/gender/etc and #.

r --no-save < s.r

This generates the file out.csv - which you can use for your visualization?

ogr2ogr -f "GeoJSON" one.json 1percent/p101_d00.shp 

*Requirements*

GDAL (brew install gdal)
r (brew install r)
spine (npm install spine)
