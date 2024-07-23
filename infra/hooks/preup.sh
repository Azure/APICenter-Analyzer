#!/bin/bash

# Load the azd environment variables
DIR=$(dirname "$(realpath "$0")")
"$DIR/load_azd_env.sh"

if [ -z "$GITHUB_WORKSPACE" ]; then
    # The GITHUB_WORKSPACE is not set, meaning this is not running in a GitHub Action
    "$DIR/login.sh"
fi
