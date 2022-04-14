"""MovieLens movies analysis"""

from pyspark.sql import SparkSession
import pyspark.sql.functions as F

SPARK_APP_NAME = "MovieLens movies Analysis"
DATABASE_NAME = "movielens"
POSTGREQSL_CONNECTOR = "jdbc"
POSTGRESQL_URL = f"{POSTGREQSL_CONNECTOR}:postgresql://postgresql-db:5432/{DATABASE_NAME}"
MOVIES_TABLE_NAME = "movies"
RATINGS_TABLE_NAME = "ratings"


def analysis():

    spark = SparkSession \
        .builder \
        .appName(SPARK_APP_NAME)\
        .getOrCreate()

    spark.sparkContext.setLogLevel('WARN')

    movies = spark.read \
        .format(POSTGREQSL_CONNECTOR) \
        .option("url", POSTGRESQL_URL) \
        .option("dbtable", MOVIES_TABLE_NAME) \
        .option("user", "postgres") \
        .option("password", "postgres") \
        .option("driver", "org.postgresql.Driver") \
        .load()

    movies.show()

if __name__ == "__main__":
    analysis()
