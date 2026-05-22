# QBit Quick Notes

## Build Windows

```powershell
bun install
bun run --cwd packages/opencode build --single --baseline
$env:RUST_TARGET="x86_64-pc-windows-msvc"
bun --cwd packages/desktop ./scripts/prepare.ts
bun run --cwd packages/desktop tauri build
.\qbit-installer\collect-windows.ps1
```

## Build Linux

```bash
bun install
bun run --cwd packages/opencode build --single --baseline
RUST_TARGET=x86_64-unknown-linux-gnu bun --cwd packages/desktop ./scripts/prepare.ts
bun run --cwd packages/desktop tauri build
./qbit-installer/collect-linux.sh
```

## Config File

- Windows global config: `%USERPROFILE%\.config\opencode\opencode.json`
- Linux global config: `~/.config/opencode/opencode.json`
- Project config: put `opencode.json` in the project root

## Install Config

```powershell
.\qbit-installer\install-config-windows.ps1
```

```bash
./qbit-installer/install-config-linux.sh
```

## Install Windows

```powershell
.\qbit-installer\install-config-windows.ps1
```

This does both:

- copy `opencode.json` to `%USERPROFILE%\.config\opencode\opencode.json`
- update Windows desktop model/provider state

Optional:

```powershell
.\qbit-installer\install-config-windows.ps1 -ProviderID ollama-custom -ModelID qwen3.6:35b
```
