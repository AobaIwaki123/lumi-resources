#!/usr/bin/env bash

set -euo pipefail

script_dir="$(cd "$(dirname "$0")" && pwd)"
ruby "$script_dir/validate.rb" "$script_dir/../resources.yaml"

