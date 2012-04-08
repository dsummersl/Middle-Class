Who is the Middle Class?
----

An interractive viz exploring this question.

*Notes*
----

Generally see the Cakefile for instructions - what isn't automated is documented therein.

For PUMA map:
cake -t 5percent mapcommands > a.sh ; sh a.sh

For Super PUMA map:
cake -t 1percent mapcommands > a.sh ; sh a.sh

----

Group the data by State by income/sex/gender/etc and #.

r --no-save < s.r

*Requirements*

GDAL (brew install gdal)
r (brew install r)
spine (npm install spine)
