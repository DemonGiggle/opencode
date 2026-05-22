#!/usr/bin/env bash
set -euo pipefail

script_dir="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
source_file="${script_dir}/opencode.json"
source_binary="${script_dir}/linux-x86-64/opencode"
bin_dir="${HOME}/.local/bin"
target_binary="${bin_dir}/opencode"
config_dir="${HOME}/.config/opencode"
target_file="${config_dir}/opencode.json"

if [[ ! -f "${source_file}" ]]; then
  echo "Missing source config: ${source_file}" >&2
  exit 1
fi

if [[ ! -f "${source_binary}" ]]; then
  echo "Missing source binary: ${source_binary}" >&2
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

mkdir -p "${bin_dir}"
mkdir -p "${config_dir}"

if ask_overwrite "${target_binary}"; then
  cp -f "${source_binary}" "${target_binary}"
  chmod +x "${target_binary}"
  copied_files+=("${target_binary}")
else
  skipped_files+=("${target_binary}")
fi

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
echo "binary=${target_binary}"
echo "config=${target_file}"

case ":${PATH}:" in
  *":${bin_dir}:"*)
    ;;
  *)
    echo
    echo "${bin_dir} is not in PATH."
    echo 'Add this line to your shell config:'
    echo
    echo 'export PATH="$HOME/.local/bin:$PATH"'
    ;;
esac
