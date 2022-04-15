"""MovieLens movies analysis"""

from pyspark.sql import SparkSession
import pyspark.sql.functions as F

SPARK_APP_NAME = "MovieLens movies Analysis"
DATABASE_NAME = "movielens"
DB_CONNECTOR = "jdbc"
POSTGRESQL_URL = f"{DB_CONNECTOR}:postgresql://postgresql-db:5432/{DATABASE_NAME}"
# POSTGRESQL_URL = f"{DB_CONNECTOR}:postgresql://postgres:postgres@postgresql-db:5432/{DATABASE_NAME}"
MOVIES_TABLE_NAME = "movies"
RATINGS_TABLE_NAME = "ratings"

# import os
# os.environ["PYSPARK_SUBMIT_ARGS"] = "--packages postgresql-42.2.19.jar movies_analysis/main.py"
# os.environ["SPARK_CLASSPATH"] = "/opt/workspace movies_analysis/main.py"

def analysis():

spark = SparkSession \
    .builder \
    .appName(SPARK_APP_NAME) \
    .master("spark://spark-master:7077") \
    .config("spark.submit.deployMode","cluster") \
    .config("spark.jars", "/opt/workspace/postgresql-42.2.19.jar,/opt/workspace/checker-qual-3.5.0.jar") \
    .getOrCreate()

        # .config("spark.jars.packages", "org.postgresql:postgresql:42.2.19,checker-qual-3.5.0.jar") \

    spark.sparkContext.addPyFile("/opt/workspace/postgresql-42.2.19.jar,/opt/workspace/checker-qual-3.5.0.jar")

    spark.sparkContext.setLogLevel('WARN')

    movies = spark.read \
        .format(DB_CONNECTOR) \
        .option("url", POSTGRESQL_URL) \
        .option("dbtable", MOVIES_TABLE_NAME) \
        .option("user", "postgres") \
        .option("password", "postgres") \
        .option("driver", "org.postgresql.Driver") \
        .load()

    movies.show()

if __name__ == "__main__":
    analysis()
