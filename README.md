Who is the Middle Class?
----

An interractive viz exploring this question.

*Requirements*
----

Spine: brew install spine
Mongodb: brew install mongodb

Do this, once its all checked out:

npm install .

mongod run --config /usr/local/Cellar/mongodb/2.0.4-x86_64/mongod.conf

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
