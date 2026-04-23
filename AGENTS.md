# Agent Instructions

## Project Context

This is **`daveli0223/vscode-copilot-chat-sidecar`** — a personal fork of
`microsoft/vscode-copilot-chat` that adds a mobile phone "sidecar" bridge to
VS Code's Copilot Chat. It lets you view chat history and send messages from a
phone PWA while coding on the desktop.

### Tech Stack
- **TypeScript** — extension host code (`src/`)
- **VS Code Extension API** — proposed APIs for chat, language models
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
- `src/platform/bridge/vscode-node/conversationBridge.ts` — bridge ↔ VS Code glue
- `src/extension/conversation/vscode-node/sidecarContribution.ts` — tunnels & settings
- `pwa/js/app.js` — PWA main app logic
- `pwa/js/chat-renderer.js` — PWA message rendering
- `script/reinstall-sidecar.sh` — build VSIX and reinstall into VS Code

### Build & Dev
```bash
# Build and reinstall extension
./script/reinstall-sidecar.sh

# Push (git-lfs hook workaround)
git push --no-verify origin feat/proxy
```

## Session Wrap — Changelog Workflow

After any non-trivial session, automatically run the session-wrap workflow:

1. Identify what was produced: source changes, configs, discoveries, or procedures.
2. Stage and commit source changes using conventional commits.
3. Append to `CHANGELOG.md` using Keep a Changelog format (create if absent).

**Trigger phrases (run without asking):** "wrap up", "commit findings",
"save and commit", "update changelog", "log our changes", "commit the fix".

## Conventions

- Conventional Commits: `feat:`, `fix:`, `docs:`, `refactor:`, `chore:`
- Push: always `git push --no-verify origin feat/proxy`
- One commit per logical change

## Safety Rules

- Never force-push without explicit confirmation
- Never delete files without confirmation
