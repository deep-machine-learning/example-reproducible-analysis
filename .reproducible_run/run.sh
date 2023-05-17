#!/usr/bin/env bash

##################
# GET ANALYSIS NAME AND GENERATE ANALYSIS VERSION
##################
# Read the YAML file
yaml=$(cat environment/config.yaml)

ANALYSIS_NAME=${PWD##*/} # get name from parent directory
ANALYSIS_VERSION=$(uuidgen | cut -c-8) # generate unique id
AWS_ACCOUNT=$(aws sts get-caller-identity --query Account --output text)
AWS_REGION=$(aws configure get region)
ANALYSIS_BUCKET=s3://sagemaker-${AWS_REGION}-${AWS_ACCOUNT}

#################
# VERSIONING DATASET
#################
dvc add data/
dvc push

##################
# LAUNCH CODEBUILD PROJECT
##################
# aws codebuild start-build --project-name reproducible-run

##################
# BUILD AND PUSH CONTAINER TO ECR
##################
CONTAINER_FULLNAME="${AWS_ACCOUNT}.dkr.ecr.${AWS_REGION}.amazonaws.com/${ANALYSIS_NAME}:${ANALYSIS_VERSION}"
# If the repository doesn't exist in ECR, create it.
aws ecr describe-repositories --repository-names "${ANALYSIS_NAME}" > /dev/null 2>&1
if [[ $? -ne 0 ]]
then
    aws ecr create-repository --repository-name "${ANALYSIS_NAME}" > /dev/null
fi
# Get the login command from ECR and execute it directly
$(aws ecr get-login --region ${AWS_REGION} --no-include-email)
# Build the docker image locally with the image name and then push it to ECR
echo "===== BUILDING CONTAINER IMAGE ====="
docker build --no-cache -t ${ANALYSIS_NAME} -f environment/Dockerfile .
docker tag ${ANALYSIS_NAME} ${CONTAINER_FULLNAME}
echo "===== PUSHING CONTAINER IMAGE TO ECR ====="
docker push ${CONTAINER_FULLNAME}

##################
# LAUNCH JOB IN SAGEMAKER
##################
echo "===== RUNNING THE ANALYSIS ON AWS ====="
python .reproducible_run/job.py \
    --job_name ${ANALYSIS_NAME}-${ANALYSIS_VERSION} \
    --container_image ${CONTAINER_FULLNAME} \
    --entrypoint code/entrypoint.sh \
    --output_path ${ANALYSIS_BUCKET}/runs

echo "===== DOWNLOADING RESULTS ====="
aws s3 cp ${ANALYSIS_BUCKET}/runs/${ANALYSIS_NAME}-${ANALYSIS_VERSION}/results.dvc .
rm -r results/*
dvc pull
echo "===== ANALYSIS EXECUTED SUCCESSFULLY ====="

##################
# SAVE ANALYSIS VERSION TO GITHUB REPO
##################
echo "===== SAVING ANALYSIS INTO GITHUB ====="
git add .
git commit -m ${ANALYSIS_VERSION}
git push