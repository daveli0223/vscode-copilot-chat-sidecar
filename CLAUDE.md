# Claude Code Instructions

## Project Context

This is **`daveli0223/vscode-copilot-chat-sidecar`** — a personal fork of
`microsoft/vscode-copilot-chat` that adds a mobile phone "sidecar" bridge to
VS Code's Copilot Chat. It lets you view chat history and send messages from a
phone PWA while coding on the desktop.

### Tech Stack
- **TypeScript** — extension host code (`src/`)
- **VS Code Extension API** — proposed APIs for chat participants, language models
- **Node.js HTTP + WebSocket** — bridge server (`src/platform/bridge/`)
- **Vanilla JS PWA** — phone web app (`pwa/`)
- **Tunnel providers** — cloudflared (default), ngrok, devtunnel

### Branch Layout
```
upstream/main  (microsoft/vscode-copilot-chat)
    └── sidecar          (3 sidecar-specific commits)
        └── feat/proxy   (active dev: tunnel, PWA, proxy improvements)
```

### Key Files
- `src/platform/bridge/node/bridgeServer.ts` — HTTP + WebSocket bridge server
- `src/platform/bridge/vscode-node/conversationBridge.ts` — bridge ↔ VS Code conversation glue
- `src/extension/conversation/vscode-node/sidecarContribution.ts` — tunnel management, settings
- `pwa/js/app.js` — PWA main app logic
- `pwa/js/chat-renderer.js` — PWA message rendering
- `pwa/css/style.css` — PWA styles
- `script/reinstall-sidecar.sh` — build VSIX and reinstall into VS Code

### Build & Dev
```bash
# Build and reinstall extension
./script/reinstall-sidecar.sh

# Push (git-lfs hook workaround)
git push --no-verify origin feat/proxy
```

### Tunnel Providers
Default is **cloudflare** (unlimited concurrent free tunnels, no account needed).
Set via `"github.copilot.sidecar.tunnelProvider"` VS Code setting.

## Session Wrap — Changelog Workflow

After any non-trivial session, run the session-wrap workflow:

1. Scan the session for changes or findings worth preserving.
2. Stage and commit all source changes with a conventional commit message.
3. Update `CHANGELOG.md` (Keep a Changelog format) with what happened.

**Trigger phrases (run without asking):** "wrap up", "commit findings",
"save and commit", "update changelog", "log our changes", "commit the fix".

## Git Conventions

- Conventional Commits: `feat:`, `fix:`, `docs:`, `refactor:`, `chore:`
- Always use `--no-verify` when pushing: `git push --no-verify origin feat/proxy`
- Never force-push without confirmation
- Never delete files without confirmation
