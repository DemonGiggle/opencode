#!/usr/bin/env bash
set -euo pipefail

script_dir="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
source_file="${script_dir}/opencode.json"
config_dir="${HOME}/.config/opencode"
target_file="${config_dir}/opencode.json"

if [[ ! -f "${source_file}" ]]; then
  echo "Missing source config: ${source_file}" >&2
  exit 1
fi

copied_files=()
skipped_files=()

ask_overwrite() {
  local target="$1"

  if [[ -e "${target}" ]]; then
    read -r -p "'${target}' already exists. Overwrite? [y/N] " answer
    case "${answer}" in
      y|Y|yes|YES)
        return 0
        ;;
      *)
        return 1
        ;;
    esac
  fi

  return 0
}

mkdir -p "${config_dir}"

if ask_overwrite "${target_file}"; then
  cp -f "${source_file}" "${target_file}"
  copied_files+=("${target_file}")
else
  skipped_files+=("${target_file}")
fi

echo
echo "Copied files:"
if [[ "${#copied_files[@]}" -eq 0 ]]; then
  echo "  None"
else
  for file in "${copied_files[@]}"; do
    echo "  ${file}"
  done
fi

echo
echo "Skipped files:"
if [[ "${#skipped_files[@]}" -eq 0 ]]; then
  echo "  None"
else
  for file in "${skipped_files[@]}"; do
    echo "  ${file}"
  done
fi

echo
echo "Install complete."
echo "config=${target_file}"
