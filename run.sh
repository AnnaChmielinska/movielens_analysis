#! /usr/bin/env bash

if [ "$#" -ne 0 ] ; then
    echo "Wrong number of arguments. Usage: ${0}"
    exit 1
fi

function clean_up {
    echo -e "\nTearing down the Docker environment, please wait.\n"
    docker-compose logs > logs.txt
    docker-compose down -v #--rmi all --remove-orphans
}

set -e

export WORKDIR=$(cd "$(dirname "${0}")"; pwd -P)
cd "${WORKDIR}"

export ENV_FILE=.env
export DATABASE_NAME="movielens"

if [ ! -f "${ENV_FILE}" ]; then
  echo "${ENV_FILE} file does not exist! Exiting..."
  exit 1
else
  export $(grep -v '^#' ${ENV_FILE} | xargs)
fi


echo "
==========================================================================================================
Starting Docker ...
==========================================================================================================
"
docker-compose up -d

echo "
==========================================================================================================
Setting up containers environment ...

"
trap clean_up EXIT

sleep 10

# echo -e "\nCreating movielens database structures.\n"
# docker-compose exec postgresql-db psql -h localhost -U postgres -f '/movielens_database/ddl/create_db.sql'
# docker-compose exec postgresql-db psql -h localhost -U postgres -f '/movielens_database/ddl/create_movies.sql'
# docker-compose exec postgresql-db psql -h localhost -U postgres -f '/movielens_database/ddl/create_ratings.sql'
docker-compose exec postgresql-db psql -d "${DATABASE_NAME}" -U postgres -c '\dt+'

echo -e "\nLoading movielens data into tables.\n"
docker-compose exec postgresql-db psql -d "${DATABASE_NAME}" -U postgres -f '/movielens_database/dml/01_load_movies.sql'
docker-compose exec postgresql-db psql -d "${DATABASE_NAME}" -U postgres -f '/movielens_database/dml/02_load_ratings.sql'
docker-compose exec postgresql-db psql -d "${DATABASE_NAME}" -U postgres -c '\dt+'

echo "
==========================================================================================================

"

echo "
==============================================================================================================
Movies analytics

"

echo "
PostgreSQL -- port ${POSTGRES_PORT}
Spark Master -- port ${SPARK_MASTER_PORT}
Jupyter notebook -- port ${JUPYTER_PORT}
==============================================================================================================
"

echo -e "\nExecuting main Spark application\n"
# docker-compose exec spark-master apk add py3-numpy
docker-compose exec spark-master \
    /spark/bin/spark-submit \
    --packages org.postgresql:postgresql:42.2.5 \
    movies_analysis/main.py

read -r -d '' _ </dev/tty
