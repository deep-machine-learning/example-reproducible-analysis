#!/usr/bin/env bash
# This is the master script for the capsule. When you click "Reproducible Run", the code in this file will execute.

##################
# PREREQUISITES
##################
dvc pull
pip install -r requirements.txt

##################
# LAUNCH CONTAINER JOB
##################
python code/main.py

##################
# ADD RESULTS TO S3
##################
# dvc add results/
# dvc push
