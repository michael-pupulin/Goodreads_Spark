import org.apache.log4j.Logger._
import org.apache.log4j.{Level, Logger}
import org.apache.spark.sql.functions.col
import org.apache.spark.sql.{DataFrame, SparkSession}
object Main {
  Logger.getLogger("org").setLevel(Level.OFF)
  Logger.getLogger("akka").setLevel(Level.OFF)
  val spark: SparkSession = SparkSession
    .builder
    .appName("goodreads")
    .config("spark.master", "local")
    .getOrCreate()


  // Replace Key with your AWS account key (You can find this on IAM
  spark.sparkContext
    .hadoopConfiguration.set("fs.s3a.access.key", "Access")
  // Replace Key with your AWS secret key (You can find this on IAM
  spark.sparkContext
    .hadoopConfiguration.set("fs.s3a.secret.key", "Secret")
  spark.sparkContext
    .hadoopConfiguration.set("fs.s3a.endpoint", "s3.amazonaws.com")



//for aws read
 val df: DataFrame = spark.read.option("inferSchema","true")
   .json("s3a://pupulin-goodreads/goodreads_books.json")



  df.show(5)





  val SSavg_year: DataFrame = df.filter(col("publisher")==="Penguin Books" ||
    col("publisher")==="Random House" ||
    col("publisher")==="Penguin Random House")
    .select(col("publication_year"), col("average_rating").cast("double"))
    .groupBy(col("publication_year"))
    .mean("average_rating")

  SSavg_year.show(10)

  val PRavg_year: DataFrame = df.filter(col("publisher")==="Simon & Schuster")
    .select(col("publication_year"), col("average_rating").cast("double"))
    .groupBy(col("publication_year"))
    .mean("average_rating")

  PRavg_year.show(10)
//  //writing
  PRavg_year.coalesce(1).write.csv("s3a://pupulin-goodreads/avg_pr_by_yr.csv")
  SSavg_year.coalesce(1).write.csv("s3a://pupulin-goodreads/avg_ss_by_yr.csv")
  def main(args: Array[String]): Unit = {
    println("done")
  }
}
