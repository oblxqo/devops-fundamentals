#!/bin/bash

# Check if jq is installed
if ! command -v jq &> /dev/null; then
  echo "jq is not installed. Please install it:"
  echo "AlmaLinux or Ubuntu: sudo yum install jq"
  echo "macOS: brew install jq"
  echo "Windows: chocolatey install jq"
  exit 1
fi

# Check if necessary properties exist
function check_necessary_properties {
  # Check metadata property
  local metadata_result=$(jq '."metadata"?."pipelineArn"' "$PIPELINE_JSON")
  if [ "$metadata_result" == "null" ]; then
    echo "Metadata property is missing in the JSON definition file."
    exit 1
  fi

  # Check Source properties
  local source_props=("Branch" "Owner" "PollForSourceChanges" "Repo")
  for prop in "${source_props[@]}"; do
    local result=$(jq --arg prop "$prop" '."pipeline"."stages"[] | select(.name == "Source") | .actions[] | select(.name == "Source") | .configuration."$prop"' "$PIPELINE_JSON" 2>/dev/null)
    if [ "$result" != "null" ] || [ -z "$result" ]; then
      echo "Source.$prop property is missing in the JSON definition file."
      exit 1
    fi
  done

  # Check EnvironmentVariables property
  local is_env_vars_result_missing=$(jq '."pipeline"."stages" | map(select((.name == "QualityGate") or (.name == "Build"))) | any(.[].actions[]; has("configuration") == false or (.configuration | has("EnvironmentVariables") | not))' "$PIPELINE_JSON" 2>/dev/null)
  if [ "$is_env_vars_result_missing" == true ] || [ -z "$is_env_vars_result_missing" ]; then
    echo "EnvironmentVariables property is missing in the JSON definition file."
    exit 1
  fi
}

# Removes the metadata and increments the pipeline version
function process_pipeline_base {
  local base_json=$(jq '
    if .metadata then
      del(.metadata)
    else .
    end
  | ."pipeline"."version" += 1
  ' "$PIPELINE_JSON")
  echo "$base_json"
}

# Process Source properties
function process_source_properties {
  local base_json="$1"
  local source_json=$(jq --arg OWNER "$OWNER" --arg BRANCH "$BRANCH" --arg POLL_FOR_SOURCE_CHANGES "$POLL_FOR_SOURCE_CHANGES" --arg REPO "$REPO" '
    ."pipeline"."stages" |= (
      map(if .name == "Source" then
        .actions |= map(
          if .name == "Source" then
            .configuration.Branch = $BRANCH
          | .configuration.Owner = $OWNER
          | .configuration.PollForSourceChanges = $POLL_FOR_SOURCE_CHANGES
          | .configuration.Repo = $REPO
          else . end
        )
      else . end))
    ' <<< "$base_json")
  echo "$source_json"
}

# Process EnvironmentVariables properties
function process_environment_variables {
  local base_json="$1"
  local env_json=$(jq --arg CONFIGURATION "$CONFIGURATION" '
    ."pipeline"."stages" |= (
      map(if .name == "QualityGate" or .name == "Build" then
        .actions |= map(
          .configuration.EnvironmentVariables = (
            (.configuration.EnvironmentVariables | fromjson)
            | map(if .name == "BUILD_CONFIGURATION" then .value = $CONFIGURATION else . end)
            | tojson
          ))
      else . end))
    ' <<< "$base_json")
  echo "$env_json"
}

# Parse input arguments
while [[ "$#" -gt 0 ]]; do
  case $1 in
    --owner) OWNER="$2"; shift ;;
    --branch) BRANCH="$2"; shift ;;
    --poll-for-source-changes) POLL_FOR_SOURCE_CHANGES="$2"; shift ;;
    --repo) REPO="$2"; shift ;;
    --configuration) CONFIGURATION="$2"; shift ;;
    --help)
      echo "Usage: $0 path-to-pipeline-json [--owner owner] [--branch branch] [--poll-for-source-changes true|false] [--repo repository] [--configuration configuration]"
      exit 0
      ;;
    *)
      if [ -z "$PIPELINE_JSON" ]; then
        PIPELINE_JSON="$1"
      else
        echo "Unrecognized option: $1"
        exit 1
      fi
  esac
  shift
done

# Check if pipeline definition JSON path to file is provided
if [ ! -f "$PIPELINE_JSON" ]; then
  echo "Provide a path to pipeline definition JSON file."
  exit 1
fi

check_necessary_properties

NEW_PIPELINE_JSON=$(process_pipeline_base)

if [ ! -z "$OWNER" ] || [ ! -z "$BRANCH" ] || [ ! -z "$POLL_FOR_SOURCE_CHANGES" ] || [ ! -z "$REPO" ]; then
  NEW_PIPELINE_JSON=$(process_source_properties "$NEW_PIPELINE_JSON")
fi

if [ ! -z "$CONFIGURATION" ]; then
  NEW_PIPELINE_JSON=$(process_environment_variables "$NEW_PIPELINE_JSON")
fi

# Save new pipeline definition
DATE_OF_CREATION=$(date +%Y-%m-%d_%H-%M-%S)
echo "$NEW_PIPELINE_JSON" >"pipeline-${DATE_OF_CREATION}.json"
