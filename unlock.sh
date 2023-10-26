#!/bin/sh
set -e

load_secrets() {
  # Load all docker secrets into this scripts env. This will override any matching global vars
  for var in $(env | grep '^FILE__'); do
    var_name=$(echo "$var" | cut -d= -f1)
    var_value=$(echo "$var" | cut -d= -f2)

    if [ -f "$var_value" ]; then
      # Read the file contents and store them in a new variable
      new_var_name="${var_name#FILE__}"  # Remove 'FILE__' prefix
      secret="$(cat "$var_value")"

      # Set the new variable with the secret value
      export "$new_var_name=$secret"
    else
      echo "Secret file does not exist: $var_value"
      exit 1
    fi
  done
}

load_api_token() {
  # Set api token from env
  if [ -n "$TRUENAS_API_KEY" ]; then
      api_token="$TRUENAS_API_KEY"
  else
      echo "'TRUENAS_API_KEY' has not been set as env var or docker secret"
      exit 1
  fi
}

is_locked() {
  pool="$1"
  dataset="$2"

  # Check if dataset is locked or not
  curl_response_file="$(mktemp)"
  http_code="$(
    curl -X 'GET' \
    "https://$TRUENAS_HOST/api/v2.0/pool/dataset?id=$pool/$dataset" \
    -H 'accept: */*' \
    -H "Authorization: Bearer $api_token" \
    --output "$curl_response_file" \
    --write-out "%{http_code}" \
    --connect-timeout 2 \
    --silent \
    --insecure \
  )"
  # Handle non 200 code
  if [ "$http_code" -ne 200 ]; then
    echo "Error: curl received a $http_code code"
    cat "$curl_response_file" && echo ""
    rm "$curl_response_file"
    return 1
  fi

  locked="$(jq '.[].locked' "$curl_response_file")"
  rm "$curl_response_file"
  # Handle invalid json response (Happens even with a 200)
  if [ -z "$locked" ]; then
    echo "Invalid response from api"
    return 1
  fi
  # Return 0 for locked, else 1
  if [ "$locked" = 'true' ]; then
    return 0
  elif [ "$locked" = 'false' ]; then
    echo "$pool/$dataset is already unlocked"
    return 1
  else
    echo "Error: got an unexpected value '$locked' for $pool/$dataset 'locked' status"
  fi
}

unlock (){
  pool="$1"
  dataset="$2"
  dataset_path="$pool/$dataset"
  passphrase="$3"

  curl_response_file="$(mktemp)"
  json=$(jq --null-input \
    --arg dataset_path "$dataset_path" \
    --arg passphrase "$passphrase" \
    '
      {
        "id": $dataset_path,
        "unlock_options": {
          "key_file": false,
          "recursive": false,
          "force": true,
          "toggle_attachments": true,
          "datasets": [
            {
              "name": $dataset_path,
              "passphrase": $passphrase
            }
          ]
        }
      }
    '
  )
  http_code="$(
    curl -X 'POST' \
    "https://$TRUENAS_HOST/api/v2.0/pool/dataset/unlock" \
    -H 'accept: */*' \
    -H "Authorization: Bearer $api_token" \
    -H 'Content-Type: application/json' \
    -d "$json" \
    --connect-timeout 2 \
    --output "$curl_response_file" \
    --write-out "%{http_code}" \
    --insecure \
    --silent
  )"

  # Log non-200 response and cleanup
  if [ "$http_code" -ne 200 ]; then
    echo "Error: curl received a $http_code code"
    cat "$curl_response_file" && echo ""
  else
    echo "Got a 200 code in response to unlocking request. Does not imply success unfortunately"
    echo "Run again to get the 'locked' status for $dataset_path"
  fi
  rm "$curl_response_file"
}

# Unlock script start point
echo "Starting unlock script"
load_secrets
load_api_token

# Verify Necessary environment variables exist
if [ -z "$TRUENAS_HOST" ]; then
  echo "Error: Missing 'TRUENAS_HOST' environment variable"
  exit 1
fi

zfs_env_vars="$(env | grep '^ZFS__')" || true;
if [ -z "$zfs_env_vars" ]; then
  echo "Error: Missing 'ZFS__' environment variables"
  exit 1
fi

for zfs_var in $zfs_env_vars; do
  # Set dataset and pool names
  # Expecting 'ZFS__<pool name>__<dataset__name>=<zfs passphrase>''
  passphrase=$(echo "$zfs_var" | cut -d= -f2)
  var=$(echo "$zfs_var" | cut -d= -f1)
  var="${var#ZFS__}"  # Remove 'ZFS__' prefix
  pool="${var%%__*}"  # Remove longest pattern from end
  dataset="${var##*__}"  # Remove longest pattern from start

  printf "\nDiscovered %s/%s, attempting to unlock now\n" "$pool" "$dataset"
  # Check if locked
  if is_locked "$pool" "$dataset"; then
    echo "$pool/$dataset is locked, attempting to unlock..."
    unlock "$pool" "$dataset" "$passphrase"
  fi
done

printf "\nFinished unlock script, exiting...\n"
