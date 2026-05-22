#!/usr/bin/env bash
set -euo pipefail

script_dir="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
source_file="${script_dir}/opencode.json"

if [[ ! -f "${source_file}" ]]; then
  echo "Missing source config: ${source_file}" >&2
  exit 1
fi

config_dir="${HOME}/.config/opencode"
target_file="${config_dir}/opencode.json"

mkdir -p "${config_dir}"
cp "${source_file}" "${target_file}"

echo "${target_file}"
