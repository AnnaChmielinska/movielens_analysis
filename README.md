# MovieLens movies analysis

This repo showcases data analysis on publicly available, non-commercial data set form [grouplens](https://grouplens.org/datasets/movielens/latest/) (ml-latest-small.zip)

## Architecture

Application runs in docker compose and consists of:
- PostgreSQL database (port `5432`)
- Spark with a master node (port `8080`) and two worker nodes listening on ports `8081` and `8082` respectively.
- Jupyter notebook server (port `8888`)

The PostgreSQL is used to ingest data from `/resources`.

__Note__: You may have to check if ports mentioned above are open (you can change port values in `.env` file).

__Note__: You may have to mark the .sh file as runnable with the `chmod` command i.e. `chmod +x run.sh`

To verify Spark master and worker nodes are online navigate to http://localhost:8080. Jupter notebook should be available under link http://localhost:8888 (access token: `'jupyter'`).

## How to build and run

The application is intended to be run in python3 virtual environment.

To setup environment run:

```
python3 -m venv <venv_name>
source <venv_name>/bin/activate
<venv_name>/bin/bin/python3 -m pip install -r requirements.txt
```
To start docker containers run:

```
bash run.sh
```

Or just run:

```
make run
```

## How to clean up

To stop Docker containers and remove container and related resources run:

```
docker-compose -f docker/docker-compose.yml down -v --rmi all --remove-orphans
<venv_name>/bin/bin/python3 -m pip uninstall -r requirements.txt -y
deactivate
```
