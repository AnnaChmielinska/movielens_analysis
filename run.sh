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
export DATABASE_NAME="movielens"

# (
# if lsof -Pi :27017 -sTCP:LISTEN -t >/dev/null ; then
#     echo "Please terminate the local mongod on 27017"
#     exit 1
# fi
# )

# echo '''
# ==========================================================================================================
# Buliding Docker containers ...
# ==========================================================================================================
# '''
# docker-compose build

echo '''
==========================================================================================================
Starting Docker ...
==========================================================================================================
'''
docker-compose up -d

echo '''
==========================================================================================================
Setting up containers environment ...

'''
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

echo '''
==========================================================================================================

'''

echo '''
==============================================================================================================
Movies analytics

'''

echo '''
PostgreSQL - port 5432

==============================================================================================================
'''

echo -e "\nExecuting main Spark application\n"


read -r -d '' _ </dev/tty
