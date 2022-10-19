ThisBuild / version := "0.1.0-SNAPSHOT"


ThisBuild / scalaVersion := "2.11.0"

lazy val root = (project in file("."))
  .settings(
    name := "goodreads",
    libraryDependencies += "org.apache.spark" % "spark-core_2.11" % "2.4.8",
    libraryDependencies += "org.apache.spark" % "spark-sql_2.11" % "2.4.8",
    libraryDependencies += "org.apache.hadoop" % "hadoop-common" % "3.3.2",
    libraryDependencies += "org.apache.hadoop" % "hadoop-client" % "3.3.2",
    libraryDependencies += "org.apache.hadoop" % "hadoop-aws" % "3.3.2",
    //libraryDependencies += "org.apache.hadoop" % "hadoop-cloud" % "2.7.3",
    libraryDependencies += "com.amazonaws" % "aws-java-sdk-pom" % "1.12.315",
    //libraryDependencies +="com.github.jkugiya" %% "aws-v4-signer-scala" % "0.13"
      libraryDependencies += "com.fasterxml.jackson.module" % "jackson-module-scala_2.11" % "2.13.0"
  )
