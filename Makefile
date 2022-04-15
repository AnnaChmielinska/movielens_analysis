#
# Makefile
#

# set default values
APP_DIR=movies_analysis

#===================================================
virtualenv:
	$(info ================================ SETIING VIRTUALENV ================================)
	python3 -m venv venv
	source venv/bin/activate

requirements:
	$(info ================================ INSTALLING REQUIREMENTS ================================)
	venv/bin/python3 -m pip install -r requirements.txt
	touch $@

lint: requirements
	python -m pylint --version
	python -m pylint ${APP_DIR} || true

run: requirements
	$(info ================================ RUNNING APPLICATION ================================)
	bash ./run.sh
.PHONY: lint
