#!/bin/bash

########################################################################################
### Define environment variables
########################################################################################

export GH_TOKEN=$POC_GITHUB_TOKEN
export GH_API_VERSION="2022-11-28"
export API_BASE="https://api.github.com"
export OWNER="poc-pipeline"


########################################################################################
### Validate the GitHub Token is on environment
########################################################################################
if [ -z ${GH_TOKEN} ]; then
    echo "GH_TOKEN is not set"
    exit 1;
fi


########################################################################################
### Define structures
########################################################################################

GH_HEADERS=(
  -H "Accept: application/vnd.github+json"
  -H "Authorization: Bearer ${GH_TOKEN}"
  -H "X-GitHub-Api-Version: ${GH_API_VERSION}"
)

########################################################################################
### Define functions
########################################################################################

gh_curl (){
    # The GH_HEADERS array will be expanded here
    # $@ will expand any additional argument
    curl -sS -L "${GH_HEADERS[@]}" "$@"
}

########################################################################################
### Define timestamp variable to get current date values
### Define responses_path to define where store the json responses
########################################################################################
timestamp=$(date +%Y%m%d%H%M%S)
responses_path="../responses/${timestamp}"

echo "timestamp: ${timestamp}"

########################################################################################
### Inputs from the program
### repo
### branch
########################################################################################
repo="poc-scanning-juice-shop"
branch="main"


echo
echo "########################################################################################"
echo "List the available the worflows (pipelines)  from respository ${repo} in organization ${OWNER}"
echo "This is usefull to get the pipeline in the dashboard and select one"
echo "########################################################################################"

gh_curl "${API_BASE}/repos/${OWNER}/${repo}/actions/workflows" \
-o ${responses_path}_workflows.json
jq '.workflows[] | {id, name, path, state, created_at, updated_at}' ${responses_path}_workflows.json

echo
echo "########################################################################################"
echo "List recent runs in branch ${branch}"
echo "This is usefull to see a certain number of pipelines execution in the branch ${branch}"
echo "########################################################################################"

gh_curl "${API_BASE}/repos/${OWNER}/${repo}/actions/runs?branch=${branch}&per_page=10" \
-o ${responses_path}_workflow_runs.json


echo
echo "########################################################################################"
echo "Take the first item in workflow_runs and get the run_id"
echo "########################################################################################"
run_id=$(jq -r '.workflow_runs[0].id' ${responses_path}_workflow_runs.json)
echo "Selected RUN_ID=${run_id}"

echo
echo "########################################################################################"
echo "Get details from the workflow with run_id ${run_id}"
echo "########################################################################################"
gh_curl "${API_BASE}/repos/${OWNER}/${repo}/actions/runs/${run_id}" \
-o ../responses/${timestamp}_workflow_run_detail.json


echo
echo "########################################################################################"
echo "Get the josb from the workflow with run_id ${run_id}"
echo "With a selected run get the jobs of that piepline"
echo "########################################################################################"
gh_curl "${API_BASE}/repos/${OWNER}/${repo}/actions/runs/${run_id}/jobs?filter=latest&per_page=100" \
-o ${responses_path}_jobs.json

echo
echo "########################################################################################"
echo "Get the jobs from the workflow with run_id ${run_id}"
echo "########################################################################################"
jq '.jobs[] | {id, name, status, conclusion}' ${responses_path}_jobs.json


echo
echo "########################################################################################"
echo "Get the the first job id froms run_id ${run_id}"
echo "########################################################################################"
job_id=${job_id:-$(jq -r '.jobs[0].id' ${responses_path}_jobs.json)}
echo "Using JOB_ID=${job_id}"

echo
echo "########################################################################################"
echo "Get details from  job with id ${job_id}"
echo "########################################################################################"
gh_curl "${API_BASE}/repos/${OWNER}/${repo}/actions/jobs/${job_id}" \
-o  ${responses_path}_job_detail.json


echo
echo "########################################################################################"
echo "Get logs from job with id ${job_id}"
echo "########################################################################################"
gh_curl "${API_BASE}/repos/${OWNER}/${repo}/actions/jobs/${job_id}/logs" \
-o  ../responses/${timestamp}_job_${job_id}.log


echo
echo "########################################################################################"
echo "Get artifacts from run ${run_id}"
echo "########################################################################################"
gh_curl "${API_BASE}/repos/${OWNER}/${repo}/actions/runs/${run_id}/artifacts" \
-o ../responses/${timestamp}_artifacts.json


#gh_curl "https://api.github.com/repos/poc-pipeline/poc-scanning-juice-shop/actions/artifacts/8642570322/zip" \
#-o ../responses/snyk.zip


#gh_curl "https://api.github.com/repos/poc-pipeline/poc-scanning-juice-shop/actions/artifacts/8642580316/zip" \
#-o ../responses/sonar.zip

