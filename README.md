# Sidecar for VS Code's GitHub Copilot

**Dispatch into VS Code's Copilot Chat from your phone, from anywhere**

> prototype; this is an early-stage experiment. It works, but expect rough edges. PRs are very welcome.

*Sidecar* is a lightweight orchestration layer for mobile access to your active Copilot Chat workflow. It lets a phone sync with and interact with the same chat session that is open on desktop, without adding relay infrastructure or installing a native phone app.

## Why this exists

Primarily because I like VS Code and don't use Claude Code - the former fits my workflow well, and I like the flexibilty Copilot provides whereby I can swap models on the fly.

Actual features of sidear:
- **Resume desktop context, not just repo context**
   Continue the exact repo/branch/chat thread already running in your desktop editor.
- **Work with local-first state**
   Interact with unpushed changes, local files, and the real host machine state.
- **Phone-first access to your IDE**
   Open from a QR pairing flow and use a touch-optimised UI.
- **Faster pick-up flow**
   Useful for quickly continuing one thread, answering a follow-up, or checking progress while you're grabbing lunch and left your Copilot running.

## Quickstart: Install as a VSIX

If you just want to run Sidecar without setting up the full dev environment, you can package and install it as a `.vsix`:

1. Install dependencies:

   ```
   npm ci
   ```

2. Disable the official `Github Copilot Chat` extension

2. Run the VS Code task **Package & Install VSIX** (Terminal → Run Task), or run it manually:

   ```
   npm run compile && npx vsce package --out copilot-chat-sidecar.vsix --allow-package-secrets sendgrid
   ```

   Then install:

   ```
   code-insiders --install-extension copilot-chat-sidecar.vsix --force
   # or: code --install-extension copilot-chat-sidecar.vsix --force
   ```

3. Reload VS Code and re-enable the `Github Copilot Chat` - this over-rides it. The Sidecar extension is now installed - **click the "Sidecar" panel at the bottom-right-hand-corner of your VS Code window** to launch.

4. Accept the default URL (`https://davidobot.net/vscode-copilot-chat-sidecar/`) unless you're self-hosting; this is just the visual layer

## Tunnel Setup

Sidecar needs a public HTTPS/WebSocket tunnel so your phone can reach the local bridge server running on your desktop. Two tunnel providers are supported. **ngrok is the default.**

---

### Option A: ngrok (recommended, default)

ngrok v3 works out of the box on macOS, Linux, and Windows and requires no Microsoft account.

#### 1. Install ngrok

| Platform | Command |
|----------|---------|
| macOS (Homebrew) | `brew install ngrok/ngrok/ngrok` |
| Linux (snap) | `snap install ngrok` |
| Windows (Chocolatey) | `choco install ngrok` |
| Any platform | Download from [ngrok.com/download](https://ngrok.com/download) and put `ngrok` on your `PATH` |

#### 2. Create a free account and add your auth token

A free account is enough. Register at [dashboard.ngrok.com](https://dashboard.ngrok.com/signup), copy your auth token, then run:

```bash
ngrok config add-authtoken <YOUR_AUTH_TOKEN>
```

This writes the token to `~/.config/ngrok/ngrok.yml` and is a one-time step. Without it ngrok still works but only one tunnel session per machine is allowed, and the URL changes every restart.

#### 3. Verify the install

```bash
ngrok version
# ngrok version 3.x.x
```

Sidecar will now automatically run `ngrok http <port>` when you click **Sidecar** in the status bar.

---

### Option B: Cloudflare Tunnel (no account required)

`cloudflared tunnel --url` creates a temporary public tunnel instantly — no Cloudflare account or login needed.

#### 1. Install cloudflared

| Platform | Command |
|----------|---------|
| macOS (Homebrew) | `brew install cloudflared` |
| Linux (Debian/Ubuntu) | See [Cloudflare downloads page](https://developers.cloudflare.com/cloudflare-one/connections/connect-networks/downloads/) |
| Windows (Chocolatey) | `choco install cloudflared` |
| Windows (winget) | `winget install Cloudflare.cloudflared` |
| Any platform | Download from [developers.cloudflare.com/cloudflare-one/connections/connect-networks/downloads](https://developers.cloudflare.com/cloudflare-one/connections/connect-networks/downloads/) |

#### 2. Verify the install

```bash
cloudflared --version
# cloudflared version 2024.x.x
```

No login or auth token required for quick tunnels.

#### 3. Select Cloudflare as the provider

```json
"github.copilot.sidecar.tunnelProvider": "cloudflare"
```

Sidecar will automatically run `cloudflared tunnel --url http://localhost:<port>` and parse the `*.trycloudflare.com` URL from its output.

> **Note:** Quick tunnel URLs change every restart. For a persistent subdomain, set up a named Cloudflare Tunnel with `cloudflared tunnel create` — but that requires a Cloudflare account.

---

### Option C: Azure Dev Tunnels

Dev Tunnels is Microsoft's tunnel service and is built into VS Code Remote. It requires a Microsoft or GitHub account.

#### 1. Install the Dev Tunnels CLI

| Platform | Command |
|----------|---------|
| macOS (Homebrew) | `brew install devtunnel` |
| Linux | `curl -sL https://aka.ms/DevTunnelCliInstall \| bash` |
| Windows (winget) | `winget install Microsoft.devtunnel` |

Full guide: [learn.microsoft.com/azure/developer/dev-tunnels/get-started](https://learn.microsoft.com/en-us/azure/developer/dev-tunnels/get-started)

#### 2. Sign in

```bash
devtunnel user login
# Follow the browser prompt to sign in with Microsoft or GitHub.
```

#### 3. Verify the install

```bash
devtunnel --version
```

#### 4. Select Dev Tunnels as the provider

Open VS Code Settings, search for **Sidecar tunnel**, and set `github.copilot.sidecar.tunnelProvider` to `devtunnel`.

Or edit `settings.json` directly:

```json
"github.copilot.sidecar.tunnelProvider": "devtunnel"
```

---

### Choosing a provider

| | ngrok | Cloudflare Tunnel | Azure Dev Tunnels |
|---|---|---|---|
| Account required | Free ngrok account | ❌ none for quick tunnels | Microsoft / GitHub account |
| Default | ✅ yes | no | no |
| Free tier limits | 1 online agent, URL changes on restart without a fixed domain | URL changes on restart | unlimited tunnels, URL changes on restart |
| WebSocket support | ✅ yes | ✅ yes | ✅ yes |
| Auth setup | Token once (`ngrok config add-authtoken`) | None | Browser login once |
| macOS / Linux / Windows | ✅ | ✅ | ✅ |

Set `github.copilot.sidecar.tunnelProvider` to `auto` to try ngrok → cloudflare → Dev Tunnels automatically.

---

## End-to-end Setup Guide

This walks you through getting Sidecar working from a clean machine.

### Prerequisites

| Requirement | Notes |
|---|---|
| Node.js 22+ | `node --version` |
| npm 10+ (bundled with Node) | `npm --version` |
| VS Code or VS Code Insiders | Insiders preferred for proposed APIs |
| GitHub Copilot subscription | Active seat required |
| A tunnel provider | ngrok (default), cloudflared, or Azure Dev Tunnels — pick one from [Tunnel Setup](#tunnel-setup) |

---

### Step 1 — Install a tunnel provider

**Fastest (no account): cloudflared**

```bash
brew install cloudflared        # macOS
# winget install Cloudflare.cloudflared   # Windows
cloudflared --version
```

Then set the provider in VS Code settings:

```json
"github.copilot.sidecar.tunnelProvider": "cloudflare"
```

**Or use ngrok (default, free account required):**

```bash
brew install ngrok/ngrok/ngrok
ngrok config add-authtoken <YOUR_TOKEN>   # get token at dashboard.ngrok.com
ngrok version   # should print 3.x.x
```

---

### Step 2 — Build and install the extension

```bash
cd /path/to/vscode-copilot-chat-sidecar
npm ci
npm run compile && npx vsce package --out copilot-chat-sidecar.vsix --allow-package-secrets sendgrid
code-insiders --install-extension copilot-chat-sidecar.vsix --force
# or: code --install-extension copilot-chat-sidecar.vsix --force
```

Or run the VS Code task **Package & Install VSIX** (Terminal → Run Task).

---

### Step 3 — Launch VS Code and configure

1. **Disable** the official `GitHub Copilot Chat` extension (Extensions sidebar → search "Copilot Chat" → Disable).
2. **Reload** VS Code (Cmd+Shift+P → "Developer: Reload Window").
3. **Sign in** to GitHub Copilot when prompted in the bottom-left corner.
4. Confirm the status bar shows `$(debug-disconnect) Sidecar` in the bottom-right corner.

---

### Step 4 — Pair your phone

1. Click **Sidecar** in the status bar.
2. Wait a few seconds — your tunnel provider starts automatically.
3. A panel opens with a QR code. The default PWA URL is `https://davidobot.net/vscode-copilot-chat-sidecar/`.
4. Scan the QR code from your phone's camera app.
5. The PWA opens in your phone browser and connects automatically.
6. The status bar updates to `$(device-mobile) Sidecar`.

---

### Step 5 — Validate

- Open a conversation in desktop Copilot Chat — it should appear in the phone's conversation list.
- Click a conversation on the phone to load its history.
- Type a message on the phone and send — it appears in the desktop chat and gets a response.
- The response streams live on the phone.

---

### Troubleshooting

| Symptom | Fix |
|---|---|
| Status bar shows a loopback warning | Tunnel didn't start — check the Output panel (GitHub Copilot Chat), verify the CLI is on PATH |
| Cloudflared not found | Run `brew install cloudflared` or download from [Cloudflare downloads](https://developers.cloudflare.com/cloudflare-one/connections/connect-networks/downloads/) |
| ngrok auth error | Run `ngrok config add-authtoken <token>` with a valid token from [dashboard.ngrok.com](https://dashboard.ngrok.com) |
| Phone shows "Connection failed" | Ensure phone and desktop have internet; scan a fresh QR from the panel |
| Conversations missing from phone | Known limitation: provider-backed sessions (Claude Code, Copilot CLI) show in list but history is empty |
| Want to switch providers | Set `github.copilot.sidecar.tunnelProvider` to `cloudflare`, `ngrok`, or `devtunnel` in settings |
| Panel shows wrong URL | Click **Set PWA URL** in the Sidecar panel and paste `https://davidobot.net/vscode-copilot-chat-sidecar/` |

---

## Development

### Sidecar architecture

- The extension starts a local HTTP + WebSocket bridge server on localhost.
- When you click **Sidecar** in the status bar, it spawns the configured tunnel provider (ngrok by default), reads the public URL from its output, and builds a signed pairing URL.
- A QR code in VS Code opens the PWA with that pairing URL (`ws` + session `token`).
- The phone PWA syncs conversation list, history, and streaming assistant chunks.
- Prompts sent from the phone are forwarded back into Copilot Chat on desktop.
- The status bar entry is `Sidecar` on the **bottom-right-hand-corner** of your window:
   - Disconnected state shows a disconnect icon.
   - Clicking `Sidecar` starts the bridge and then opens the pairing panel.

### PWA deployment

The `pwa/` directory is a static web app designed for GitHub Pages deployment. This repository includes `.github/workflows/deploy-pwa.yml`, which deploys `pwa/` to Pages on pushes to `main`.

Use my deployed Github pages URL (`https://davidobot.net/vscode-copilot-chat-sidecar/`) in the Sidecar panel when generating pairing QR codes, or deploy your own.

### Local PWA dev server

You can test without deploying GitHub Pages.

1. Start the local PWA server:

   ```
   npm run pwa:dev
   ```

   (or run the VS Code task `PWA: Dev Server`)

2. Point Sidecar to your local PWA URL:

   - For phone testing on same Wi-Fi: `http://<your-lan-ip>:4173/`
   - For desktop-only testing: `http://localhost:4173/`

3. Optional override: set `COPILOT_PWA_DEV_URL` before launching the extension host.

   - Example: `COPILOT_PWA_DEV_URL=http://<your-lan-ip>:4173/`
   - Sidecar prefers this env value over saved settings.

### Run and test locally

1. Install dependencies in the repo root:

   ```
   npm ci
   ```

2. Build and launch the extension host (VS Code task):

   ```
   Compile & Launch Extension Host
   ```

   The task prefers VS Code Insiders. If `code-insiders` is not installed, it falls back to `code` with `--enable-proposed-api github.copilot-chat`.

3. In the Extension Development Host window:

   - Disable the official GitHub Copilot Chat extension to avoid conflicts.
   - Sign in to GitHub Copilot.
   - Set up a tunnel provider — see [Tunnel Setup](#tunnel-setup) above. ngrok is the default; install it and add your auth token before this step.
   - Open a workspace and open the Chat view.

4. In the status bar, confirm Sidecar starts in disconnected state (`$(debug-disconnect) Sidecar`).

5. Click `Sidecar` to start the bridge and open the pairing panel.

6. Set a PWA URL:
   - Default hosted URL: https://davidobot.net/vscode-copilot-chat-sidecar/
   - Local dev URL: `http://0.0.0.0:4173/`

7. Scan the QR code from your phone and open the PWA.

8. Validate bidirectional sync:
   - Send a desktop chat prompt and confirm it appears on phone.
   - Send a phone prompt and confirm it appears in desktop chat.
   - Confirm assistant streaming chunks render live on phone.
   - Confirm status bar item updates from disconnected yellow to active Sidecar after startup.
   - Confirm the Sidecar panel shows a non-loopback bridge endpoint (if it shows a loopback warning, phone pairing will fail).

9. Validate reconnect behavior:
   - Disconnect/reconnect phone network.
   - Confirm status changes to reconnecting, then connected, and conversation list refreshes.

10. If pairing fails:
   - Verify your tunnel CLI is installed, on `PATH`, and authenticated (`ngrok config check` or `devtunnel user show`).
   - Check the Sidecar panel — if it shows a loopback warning, the tunnel did not start. Open the Output panel and select **GitHub Copilot Chat** for details.
   - Switch provider: set `github.copilot.sidecar.tunnelProvider` to `cloudflare`, `devtunnel`, or `ngrok` in settings and try again.
   - Regenerate token from the Sidecar panel and rescan.
   - Reopen the Sidecar panel to refresh the pairing URL.

## Keeping Up to Date

This fork tracks [microsoft/vscode-copilot-chat](https://github.com/microsoft/vscode-copilot-chat), which moves fast (~500 commits/month). The branch layout is:

```
upstream/main  ──── (latest microsoft commits)
                        │
sidecar        ──────── (sidecar-specific commits on top of upstream)
                            │
feat/proxy     ────────────── (tunnel/proxy commits on top of sidecar)
```

### Automated sync (GitHub Actions)

A scheduled workflow ([`.github/workflows/sync-upstream.yml`](.github/workflows/sync-upstream.yml)) runs **every Monday at 08:00 UTC** and automatically rebases `sidecar` onto `upstream/main`, then rebases `feat/proxy` on top of the updated `sidecar`. It skips if the branch is already current.

You can also trigger it manually from the **Actions** tab → **Sync with upstream** → **Run workflow**.

### Manual sync

If you need to sync outside the schedule:

```bash
# 1. Make sure the upstream remote exists (one-time setup)
git remote add upstream https://github.com/microsoft/vscode-copilot-chat.git

# 2. Fetch the latest upstream commits
git fetch upstream

# 3. Check how far behind sidecar is
git rev-list sidecar..upstream/main --count
# If output is 0, you're up to date — nothing to do.

# 4. Rebase sidecar onto upstream/main
git checkout sidecar
git rebase upstream/main

# 5. Rebase feat/proxy on top of the updated sidecar
git checkout feat/proxy
git rebase sidecar

# 6. Force-push both branches (history was rewritten)
git push --force-with-lease origin sidecar feat/proxy
```

> **Conflict resolution:** If `git rebase` stops with a conflict, fix the conflicting files, then run `git add <file>` and `git rebase --continue`. If things go wrong, `git rebase --abort` returns you to the pre-rebase state.

## Original Repo

This is just a fork. The original repo can be found [here](https://github.com/microsoft/vscode-copilot-chat/).

## License

Original repo licensed under the [MIT](LICENSE.txt) license.

New changes in this fork are also licensed under the [MIT](LICENSE.txt) license.
