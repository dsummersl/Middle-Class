/***
libraryDependencies ++= Seq(
    "net.sf.opencsv" % "opencsv" % "2.0"
)
*/
import au.com.bytecode.opencsv._
import java.io.FileReader
import collection.mutable._

//val interestingColumnNames = List("RT","PUMA","ST","INTP","SEX","ANC","ANC1P","ANC2P","PINCP","ADJINC","OIP","PAP","RETP","SCHL","SEMP","SSIP","SSP","WAGP","ESR")
//val interestingColumnNames = List("RT","PUMA","ST","SEX","ANC","ANC1P","ANC2P","PINCP","SCHL","ESR")
val interestingColumnNames = List("SEX","AGEP","ANC","PINCP","SCHL")
val buckets = Map(
  "< 0" -> (row:CSVRow) => false,
  "0 <= i < 10000" -> "",
  "10000 <= i < 20000" -> "",
  "20000 <= i < 30000" -> "",
  "30000 <= i < 40000" -> "",
  "40000 <= i < 50000" -> "",
  "50000 <= i < 60000" -> "",
  "60000 <= i < 70000" -> "",
  "70000 <= i < 80000" -> "",
  "80000 <= i < 90000" -> "",
  "90000 <= i < 100000" -> "",
  "i >= 100000" -> "")

// nc-age-12-sex-1-totals.csv
// So that w/o drilling into the data you immediately have totals just from the overall totals files?

// the initial state of the visualization would start with:
// 1. A map of the entire united states, with the ratio of the different classes laid on top of the map.
// 2. A map of the person's state: with the ratio of the different classes in each county or group or just state?
//    - this depends on whether i can map SPUMAs to counties. 

// when the user changes the definition of by the number of people or the $
// bill boundaries the map can be recomputed just by looking at the totals
// columns

///////////////////////////////////////////////////////////////////////////////
// 1. Compute the summary rows, by PUMA eventually /*{{{*/
///////////////////////////////////////////////////////////////////////////////

/** Convenience class for mapping between CSV rows and their values. */
class CSVRow(val row:Array[String], val columnsMap:Map[String,Int]) {
  def get(v:String):String = row(columnsMap.get(v).get)
}

val pass1 = new CSVReader(new FileReader(args(0)))

// compute a mapping between CSV column names and their indexes:
var nextLine:Array[String] = pass1.readNext()
var interestingColumns = List[Int]()
val columnsMap:Map[String,Int] = Map[String,Int]()
var indx = 0
for (c <- nextLine) { columnsMap.put(c,indx); indx+=1 }
for (c <- nextLine if interestingColumnNames.contains(c)) interestingColumns ::= nextLine.indexOf(c)

// we'll group by PUMA
val pumaMap = Map[String,Map[String,Int]]()
println((interestingColumns.reverse) map { nextLine(_).toString() } mkString(","))
// TODO print out bucket names
nextLine = pass1.readNext()
while (nextLine != null) {
    /*
    print((interestingColumns.reverse) map { nextLine(_).toString() } mkString(","))
    println
    */

    val row = new CSVRow(nextLine,columnsMap)
    if (!pumaMap.contains(row.get("PUMA"))) pumaMap.put(row.get("PUMA"),Map[String,Int]())
    val hm = pumaMap.get(row.get("PUMA")).get
    buckets.foreach { kv => 
      hm.put(kv._1,kv._2(row))
    }
    nextLine = pass1.readNext()
}

pumaMap.foreach { kv =>
  println(kv._1 +","+ (kv._2 map))
}

////////////////////////////////////////////////////////////////////////////////*}}}*/
// vim: set fdm=marker:
