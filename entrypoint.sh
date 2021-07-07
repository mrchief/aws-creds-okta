#!/usr/bin/env bash

set -u
set -o pipefail

awsDir="${HOME}/.aws"
config="${awsDir}/config"
credentials="${awsDir}/credentials"

mkdir -p "${awsDir}"
echo -e "[profile default]\noutput = json" >"$config"

# Attempt to get aws credentials via tokendito
max_attempts=10
totp_time=30
totp_error='Each code can only be used once. Please wait for a new code and try again.'
for ((attempts = 1; attempts <= $max_attempts; attempts++)); do
    echo "Requesting AWS credentials via Tokendito."
    t_error=$(tokendito --aws-profile default -ou $INPUT_OKTA_APP_URL -R $INPUT_AWS_ROLE_ARN --username $INPUT_OKTA_USERNAME --password $INPUT_OKTA_PASSWORD --mfa-method ${INPUT_OKTA_MFA_METHOD:=token:software:totp} --mfa-response $(echo $INPUT_OKTA_MFA_SEED | mintotp ${totp_time}) 2>&1 1>/dev/null)

    if [[ $? == 0 ]]; then
        echo "Succeeded getting credentials in attempt #${attempts}."
        break
    fi

    if [[ $t_error == *$totp_error* ]]; then
        echo "Attempt #${attempts} => ERROR: ${totp_error}"
        echo -e "Waiting ${totp_time} seconds before retrying...\n"
        sleep $totp_time
    else
        echo $t_error
        exit 1
    fi
done

if [[ $attempts == $((max_attempts + 1)) ]]; then
    echo "Giving up requesting credentials after ${max_attempts} attempts."
    exit 1
fi

# Exit immediately if a command exits with a non-zero status.
set -e

# Read credentials
section=
while read -r line; do
    # Get section we are currently in
    if [[ "${line}" =~ ^[[:space:]]*\[[-_.a-zA-Z0-9]+\][[:space:]]*$ ]]; then
        section="${line%]}"
        section="${section#[}"
    fi
    # Extract available aws export values
    if [ "${section}" = "default" ]; then
        if [[ "${line}" =~ ^[[:space:]]*aws_access_key_id[[:space:]]*=.*$ ]]; then
            aws_access_key_id="${line##*=*[[:space:]]}"
            echo "AWS_ACCESS_KEY_ID=${aws_access_key_id}" >> $GITHUB_ENV
            echo "::add-mask::${aws_access_key_id}"
        fi
        if [[ "${line}" =~ ^[[:space:]]*aws_secret_access_key[[:space:]]*=.*$ ]]; then
            aws_secret_access_key="${line##*=*[[:space:]]}"
            echo "AWS_SECRET_ACCESS_KEY=${aws_secret_access_key}" >> $GITHUB_ENV
            echo "::add-mask::${aws_secret_access_key}"
        fi
        if [[ "${line}" =~ ^[[:space:]]*aws_session_token[[:space:]]*=.*$ ]]; then
            aws_session_token="${line##*=*[[:space:]]}"
            echo "AWS_SESSION_TOKEN=${aws_session_token}" >> $GITHUB_ENV
            echo "::add-mask::${aws_session_token}"
        fi
    fi
done <"$credentials"
