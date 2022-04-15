"""MovieLens movies analysis"""
from pyspark.sql import SparkSession, DataFrame
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

# TODO replace print with logging

def load_data(spark: SparkSession, table_name: str) -> DataFrame:
    """Loads data from PostgresSQL database into Spark DataFrame"""
    print(f"Loading data from {table_name} table")
    return (spark.read
        .format(DB_CONNECTOR)
        .option("url", POSTGRESQL_URL)
        .option("dbtable", table_name)
        .option("user", "postgres")
        .option("password", "postgres")
        .option("driver", "org.postgresql.Driver")
        .load())


# pylint: disable=too-many-locals
# pylint: disable=too-many-statements
def analysis():
    """Main function for data analysis"""

    spark = SparkSession\
        .builder\
        .appName(SPARK_APP_NAME)\
        .master("spark://spark-master:7077")\
        .config("spark.submit.deployMode","cluster")\
        .config(
            "spark.jars",
            "/opt/workspace/postgresql-42.2.19.jar,/opt/workspace/checker-qual-3.5.0.jar"
        )\
        .getOrCreate()

        # .config("spark.jars.packages", "org.postgresql:postgresql:42.2.19,checker-qual-3.5.0.jar") \

    # spark\
    #     .sparkContext\
    #     .addPyFile("/opt/workspace/postgresql-42.2.19.jar,/opt/workspace/checker-qual-3.5.0.jar")

    spark.sparkContext.setLogLevel('WARN')

    print(f"{'='*40} BEGGING of {SPARK_APP_NAME} {'='*40}")
    movies = load_data(spark, MOVIES_TABLE_NAME)
    movies.printSchema()
    movies.show(truncate=False)

    ratings = load_data(spark, RATINGS_TABLE_NAME)
    ratings.printSchema()
    ratings.show(truncate=False)

    print("Checking data properties")
    # Check count row in describe if there are missing values
    print(f"{MOVIES_TABLE_NAME}")
    movies.describe().show(truncate=False) # no missing
    # Is movieID a primary key? Yes
    movies_id_count = movies\
        .select(F.col("movieID"))\
        .distinct()\
        .count()
    assert movies_id_count == movies.count()

    print(f"{RATINGS_TABLE_NAME}")
    ratings.describe().show(truncate=False)

    print("--> How many movies are in data set? <--")
    print(f"They are: {movies.count()} movies in dataset")
    rated_movies = ratings\
        .select(F.col("movieID"))\
        .distinct()\
        .count()
    print(f"Of which {rated_movies} are rated")

    print("--> What are top 10 movies with highest rate <--?")
    mean_ratings = ratings\
        .groupBy("movieId")\
        .agg(F.mean("rating"))

    mean_ratings_with_highest_score = mean_ratings\
        .where(F.col("avg(rating)") == 5.0)

    print(f"They are {mean_ratings_with_highest_score.count()} movies with highest possible average score")
    top10_movie_id = mean_ratings\
        .orderBy(F.col("avg(rating)")\
        .desc())\
        .limit(10)
    print("10 examples of highest ranking movies")
    top10_titles = top10_movie_id\
        .join(movies, on="movieId")\
        .select("title")
    top10_titles.show(truncate=False)

    print("--> What are 5 most often rating users? <--")
    ratings\
        .groupBy("userId")\
        .count()\
        .orderBy(F.col("count").desc())\
        .select("userId")\
        .limit(5)\
        .show()

    print("--> When was done first and last rate included in data set and what was the rated movie tittle? <--")
    # join movies with ratings
    movies_rated = movies\
        .join(ratings, on="movieId")

    print("There is more than 1 rating added at the begining")
    first_rate_agg_count = movies_rated\
        .groupBy(F.col("timestamp"))\
        .count()\
        .orderBy(F.col("timestamp")\
        .asc())\
        .limit(1)
    first_rate_agg_count.show(truncate=False)

    num_first_rate = first_rate_agg_count\
        .select("count")\
        .take(1)[0][0]

    print(f"They are {num_first_rate} movies which rate was included at beginning:")
    first_rate_included = movies_rated\
        .orderBy(F.col("timestamp").asc())\
        .limit(num_first_rate)
    first_rate_included\
        .select("title", "timestamp")\
        .show(truncate=False)

    last_rate_agg_count = movies_rated\
        .groupBy(F.col("timestamp"))\
        .count()\
        .orderBy(F.col("timestamp").desc())\
        .limit(1)

    print("There is exactly 1 rating added at the end:")
    last_rate_agg_count.show(truncate=False)
    last_rate_included = movies_rated\
        .orderBy(F.col("timestamp").desc())\
        .limit(1)
    last_rate_included.select("title", "timestamp").show(truncate=False)

    print("--> Find all movies released in 1990 <--")
    movies_released_in_1990 = movies\
        .where(F.trim(F.col("title")).endswith("(1990)"))\
        .select("title")

    print(f"They are {movies_released_in_1990.count()} movies released in 1990")
    print("Here are examples:")
    movies_released_in_1990.show(truncate=False)

    print(f"{'='*40} END of {SPARK_APP_NAME} {'='*40}")

if __name__ == "__main__":
    analysis()
