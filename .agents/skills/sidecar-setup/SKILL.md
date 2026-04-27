---
name: sidecar-setup
description: "Set up, configure, troubleshoot, and maintain the Copilot Chat Sidecar — the mobile PWA bridge that lets a phone act as a remote chat UI for VS Code. Use when: setting up the sidecar from scratch, changing tunnel provider, fixing 'not connected' issues, reinstalling after VS Code auto-update overwrites it, configuring ngrok domain, or doing any sidecar dev/rebuild workflow."
---

# Copilot Chat Sidecar — Setup & Maintenance

## What is the sidecar?

A personal fork of `microsoft/vscode-copilot-chat` at `daveli0223/vscode-copilot-chat-sidecar` (`feat/proxy` branch).

It adds a **mobile PWA bridge**: a phone opens the PWA at `https://<tunnel-url>/vscod` to use VS Code Copilot Chat remotely.

- **Bridge server**: `src/platform/bridge/` — HTTP + WebSocket, one per VS Code window
- **PWA client**: `pwa/` — vanilla JS progressive web app
- **Tunnel**: Cloudflare (default), ngrok, or Azure devtunnel
- **Sidecar contribution**: `src/extension/conversation/vscode-node/sidecarContribution.ts`

## Repo & Branch

```
/Users/daveli/git/vscode-copilot-chat-sidecar
active branch: feat/proxy
```

## Build & Install

```bash
# One-shot compile + package + install VSIX
./script/reinstall-sidecar.sh

# Watch mode — auto-rebuild + reinstall on every src/pwa change
./script/reinstall-sidecar.sh --watch
# Requires: brew install fswatch
```

After install, **reload VS Code window** (`Cmd+Shift+P` → Developer: Reload Window).

## Push to remote

```bash
git push --no-verify origin feat/proxy
# --no-verify skips the git-lfs hook (not installed)
```

## VS Code Settings

All settings are under `github.copilot.sidecar.*` in VS Code settings:

| Setting | Default | Description |
|---------|---------|-------------|
| `github.copilot.sidecar.enabled` | `true` | Enable/disable the sidecar bridge and status bar item |
| `github.copilot.sidecar.tunnelProvider` | `"cloudflare"` | Tunnel provider: `auto`, `cloudflare`, `ngrok`, `devtunnel` |
| `github.copilot.sidecar.ngrokDomain` | `""` | Static ngrok domain (e.g. `your-word.ngrok-free.app`) — ngrok only |

### Recommended settings.json for daily use

```json
{
  "github.copilot.sidecar.enabled": true,
  "github.copilot.sidecar.tunnelProvider": "cloudflare"
}
```

For a stable URL (instead of random Cloudflare URL each time), use ngrok with a static domain:

```json
{
  "github.copilot.sidecar.tunnelProvider": "ngrok",
  "github.copilot.sidecar.ngrokDomain": "your-word.ngrok-free.app"
}
```

## Tunnel Providers

| Provider | Install | Notes |
|----------|---------|-------|
| **Cloudflare** (default) | `brew install cloudflared` | No account needed, random URL each session |
| **ngrok** | `brew install ngrok` | Free static domain from `dashboard.ngrok.com/domains` |
| **devtunnel** | `brew install azure-dev-tunnels` | Microsoft Azure, requires login |
| **auto** | all three | Tries ngrok → cloudflare → devtunnel in order |

## Detecting & Fixing: Sidecar Overwritten by VS Code Auto-Update

VS Code silently replaces the sidecar VSIX with the official `github.copilot-chat` from the marketplace on auto-update because they share the same extension ID.

**Detection**: The sidecar adds a `pwa/` folder inside the installed extension. When overwritten, `pwa/` is absent.

```bash
EXT_DIR=$(ls -d ~/.vscode/extensions/github.copilot-chat-* 2>/dev/null | head -1)
if [ -d "$EXT_DIR/pwa" ]; then echo "Sidecar OK"; else echo "Overwritten - reinstall"; fi
```

**Auto-fix**: The `ensure-sidecar` VS Code task runs automatically on `folderOpen` (already configured in `.vscode/tasks.json`) — it checks and reinstalls automatically.

**Manual fix**:
```bash
cd /Users/daveli/git/vscode-copilot-chat-sidecar
./script/reinstall-sidecar.sh
# Then reload VS Code window
```

## Common Troubleshooting

### PWA shows "Disconnected" or won't connect
1. Check the VS Code status bar for the sidecar tunnel URL
2. Verify the extension is the sidecar (not official): `ls ~/.vscode/extensions/github.copilot-chat-*/pwa`
3. Reinstall: `./script/reinstall-sidecar.sh` and reload window
4. Check if `cloudflared`/`ngrok` is installed for your tunnel provider

### Sidecar status bar item missing
- Check `github.copilot.sidecar.enabled` is `true` in settings
- Verify sidecar extension is installed (not the official one)

### Bridge message not appearing in PWA
See `docs/fix/pwa-sidebar-and-confirmation.md` for the full recurring-bug reference.

Key rule: every `case 'turn:X'` in `handleBridgeMessage()` (app.js) must have a corresponding `handleIncomingAssistant*()` function defined in the same file.

## Development Workflow

```bash
# 1. Make changes to src/ or pwa/
# 2. Rebuild and reinstall
./script/reinstall-sidecar.sh
# 3. Reload VS Code window
# 4. Test in PWA at the tunnel URL
# 5. Commit
git add -p
git commit -m "fix(pwa): ..."
git push --no-verify origin feat/proxy
```

## Upstream Sync

Weekly GitHub Actions job syncs upstream on Mondays. Manual sync:

```bash
git fetch upstream
git checkout sidecar && git rebase upstream/main
git checkout feat/proxy && git rebase sidecar
git push --no-verify origin sidecar feat/proxy
```

Check if behind: `git rev-list sidecar..upstream/main --count`
