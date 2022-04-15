#! /usr/bin/env bash

if [ "$#" -ne 0 ] ; then
    echo "Wrong number of arguments. Usage: ${0}"
    exit 1
fi

function clean_up {
    echo -e "\nTearing down the Docker environment, please wait.\n"
    docker-compose -f ${DOCKER_COMPOSE_FILE_PATH} logs > logs.txt
    docker-compose -f ${DOCKER_COMPOSE_FILE_PATH} down -v --rmi all --remove-orphans
}

set -e

export WORKDIR=$(cd "$(dirname "${0}")"; pwd -P)
cd "${WORKDIR}"

export DOCKER_PATH=docker
export DOCKER_COMPOSE_FILE_PATH="${DOCKER_PATH}/docker-compose.yml"
export ENV_FILE="${DOCKER_PATH}/.env"
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
docker-compose -f ${DOCKER_COMPOSE_FILE_PATH} up -d

echo "
==========================================================================================================
Setting up containers environment ...

"
trap clean_up EXIT

echo -e "\nLoading movielens data into tables.\n"
docker-compose -f ${DOCKER_COMPOSE_FILE_PATH} exec postgresql-db psql -d "${DATABASE_NAME}" -U postgres -c '\dt+'
docker-compose -f ${DOCKER_COMPOSE_FILE_PATH} exec postgresql-db psql -d "${DATABASE_NAME}" -U postgres -f '/movielens_database/dml/01_load_movies.sql'
docker-compose -f ${DOCKER_COMPOSE_FILE_PATH} exec postgresql-db psql -d "${DATABASE_NAME}" -U postgres -f '/movielens_database/dml/02_load_ratings.sql'
docker-compose -f ${DOCKER_COMPOSE_FILE_PATH} exec postgresql-db psql -d "${DATABASE_NAME}" -U postgres -c '\dt+'

echo "
==========================================================================================================

"

echo "
==============================================================================================================
Movies analytics

"

echo "
PostgreSQL -- port ${POSTGRES_PORT}
Spark Master -- port ${SPARK_MASTER_UI_PORT}
Jupyter notebook -- port ${JUPYTER_PORT}
==============================================================================================================
"

#docker jupyter-notebook exec wget https://repo1.maven.org/maven2/org/postgresql/postgresql/42.2.19/postgresql-42.2.19.jar
#docker jupyter-notebook exec wget https://repo1.maven.org/maven2/org/checkerframework/checker-qual/3.5.0/checker-qual-3.5.0.jar

echo -e "\nExecuting main Spark application\n"
docker-compose -f ${DOCKER_COMPOSE_FILE_PATH} exec spark-master \
    /spark/bin/spark-submit \
    --packages org.postgresql:postgresql:42.2.19 \
    movies_analysis/main.py

# read -r -d '' _ </dev/tty
