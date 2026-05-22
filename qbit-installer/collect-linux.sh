#!/usr/bin/env bash
set -euo pipefail

script_dir="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
root_dir="$(cd -- "${script_dir}/.." && pwd)"
target_dir="${script_dir}/linux-x86-64"

rm -rf "${target_dir}"
mkdir -p "${target_dir}"

copy_file() {
  local source="$1"

  if [[ ! -f "${source}" ]]; then
    echo "Missing build artifact: ${source}" >&2
    exit 1
  fi

  cp "${source}" "${target_dir}/$(basename "${source}")"
}

copy_file "${root_dir}/packages/opencode/dist/opencode-linux-x64-baseline/bin/opencode"
copy_file "${root_dir}/packages/desktop/src-tauri/sidecars/opencode-cli-x86_64-unknown-linux-gnu"
copy_file "${root_dir}/packages/desktop/src-tauri/target/x86_64-unknown-linux-gnu/release/OpenCode"

bundle_dir="${root_dir}/packages/desktop/src-tauri/target/x86_64-unknown-linux-gnu/release/bundle"
if [[ -d "${bundle_dir}" ]]; then
  find "${bundle_dir}" -maxdepth 2 -type f \( -name '*.deb' -o -name '*.rpm' \) -exec cp {} "${target_dir}/" \;
fi

echo "${target_dir}"
