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

  # Check version property
  local version_result=$(jq '."pipeline"?."version"' "$PIPELINE_JSON")
  if [ "$version_result" == "null" ]; then
    echo "Version property is missing in the JSON definition file."
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
  local updated_json="$base_json"
  if [ ! -z "$OWNER" ]; then
    updated_json=$(jq --arg OWNER "$OWNER" '."pipeline"."stages" |= (map(if .name == "Source" then .actions |= (map(if .name == "Source" then .configuration.Owner = $OWNER else . end)) else . end))' <<< "$base_json")
  fi
  if [ ! -z "$BRANCH" ]; then
    updated_json=$(jq --arg BRANCH "$BRANCH" '."pipeline"."stages" |= (map(if .name == "Source" then .actions |= (map(if .name == "Source" then .configuration.Branch = $BRANCH else . end)) else . end))' <<< "$updated_json")
  fi
  if [ ! -z "$POLL_FOR_SOURCE_CHANGES" ]; then
    updated_json=$(jq --arg POLL_FOR_SOURCE_CHANGES "$POLL_FOR_SOURCE_CHANGES" '."pipeline"."stages" |= (map(if .name == "Source" then .actions |= (map(if .name == "Source" then .configuration.PollForSourceChanges = $POLL_FOR_SOURCE_CHANGES else . end)) else . end))' <<< "$updated_json")
  fi
  if [ ! -z "$REPO" ]; then
    updated_json=$(jq --arg REPO "$REPO" '."pipeline"."stages" |= (map(if .name == "Source" then .actions |= (map(if .name == "Source" then .configuration.Repo = $REPO else . end)) else . end))' <<< "$updated_json")
  fi
  echo "$updated_json"
}

# Process EnvironmentVariables properties
function process_environment_variables {
  local base_json="$1"
  if [ ! -z "$CONFIGURATION" ]; then
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
  else
    echo "$base_json"
  fi
}

## Parse input arguments
should_apply_defaults=false
if [ -n "$1" ] && [ "${1:0:2}" != "--" ]; then
    PIPELINE_JSON="$1"
    shift
fi

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
      echo "Unrecognized option: $1"
      exit 1
  esac
  should_apply_defaults=true
  shift
done

# Default values
if [ "$should_apply_defaults" = "true" ]; then
  BRANCH=${BRANCH:-main}
  POLL_FOR_SOURCE_CHANGES=${POLL_FOR_SOURCE_CHANGES:-false}
fi

# Check if pipeline definition JSON path to file is provided
if [ ! -f "$PIPELINE_JSON" ]; then
  echo "Provide a path to pipeline definition JSON file."
  exit 1
fi

check_necessary_properties

NEW_PIPELINE_JSON=$(process_pipeline_base)

NEW_PIPELINE_JSON=$(process_source_properties "$NEW_PIPELINE_JSON")

NEW_PIPELINE_JSON=$(process_environment_variables "$NEW_PIPELINE_JSON")

# Save new pipeline definition
DATE_OF_CREATION=$(date +%Y-%m-%d_%H-%M-%S)
echo "$NEW_PIPELINE_JSON" > "pipeline-${DATE_OF_CREATION}.json"
