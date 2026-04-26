# PWA Fixes: Sidebar Status + Approval Dialog

These two features have been requested and broken multiple times. This doc exists so they are never accidentally regressed or forgotten.

---

## 1. Sidebar Status Description

### What it should do
While Copilot is working (streaming), each conversation item in the PWA sidebar must show a **live status description line** below the title — e.g. `Reading file...`, `Running command...`. When the turn completes, the description is removed.

### Where it is implemented
- **`pwa/js/app.js`** — `handleIncomingAssistantStatus()` calls `updateActiveConversationStatusText(message.content)` to update the sidebar in-place.
- **`pwa/js/app.js`** — `updateActiveConversationStatusText(text)` inserts/updates/removes a `.conversation-description` div inside the active `.conversation-item` without rebuilding the whole list.
- **`pwa/js/app.js`** — `handleIncomingAssistantComplete()` calls `updateActiveConversationStatusText('')` to clear the description when streaming ends.
- **`pwa/js/app.js`** — `renderConversationList()` renders `conversation.lastStatus` as a `.conversation-description` div when rebuilding the list (e.g. on reconnect).
- **`pwa/css/style.css`** — `.conversation-description` and `.conversation-description.streaming` styles.

### Common regression patterns
- Forgetting to call `updateActiveConversationStatusText('')` in `handleIncomingAssistantComplete()` → stale status text lingers after turn ends.
- Rebuilding `conversationListEl.innerHTML` during streaming → sidebar flickers and loses description.
- Not persisting `lastStatus` on the conversation object → description disappears when the list re-renders.

---

## 2. Approval / Confirmation Dialog in PWA Chat

### What it should do
When the Copilot agent needs the user to approve a terminal command or other action, a confirmation dialog must appear **inline in the PWA chat** with a title, a description/command (rendered as a code block when it looks like a shell command), and action buttons. Clicking a button sends `confirmation:respond` back over the WebSocket.

### Where it is implemented
- **`pwa/js/app.js`** — `case 'turn:confirmation'` in `handleBridgeMessage()` calls `handleIncomingAssistantConfirmation(message)`.
- **`pwa/js/app.js`** — `handleIncomingAssistantConfirmation()` passes `{ title, message, buttons }` to `renderer.appendAssistantConfirmation()`.
- **`pwa/js/chat-renderer.js`** — `appendAssistantConfirmation()` renders the dialog card with optional code block and buttons.
- **`pwa/js/app.js`** — `renderer.setConfirmationRunner()` callback sends `{ type: 'confirmation:respond', conversationId, turnId, buttonLabel }` over the WebSocket.

### Common regression pattern
`handleIncomingAssistantConfirmation` function **defined missing** — the `switch` case existed in `handleBridgeMessage()` but the function body was never written, so all `turn:confirmation` events were silently dropped with no error.

**Rule:** Any `case 'turn:X'` added to `handleBridgeMessage()` must have a corresponding `handleIncomingAssistant*()` function defined in the same file. Always verify:
1. `case` exists in the switch
2. The handler function is actually defined
3. The renderer method it calls exists in `chat-renderer.js`

## 3. Tool Invocation: Command Text Not Shown (Empty Code Block)

### What it should do
When the agent runs a terminal command via a tool, the **command line** (e.g. `npm run compile && ...`) must be visible in the chat as a styled code block **before** any output arrives. Without this, the tool item shows only a summary label and the code block area appears blank or missing.

### Where it is implemented
- **`turn:tool` bridge message** sends `commandLine` field alongside `terminalOutput`.
- **`pwa/js/chat-renderer.js`** — `appendAssistantToolInvocation()` — renders `.tool-command-line` pre-block from `tool.commandLine` (added above `tool.terminalOutput` block).
- **`pwa/css/style.css`** — `.tool-command-line` — styled with left blue accent border to distinguish the command from the output.

### Common regression pattern
Only `tool.terminalOutput` was rendered as a code block. `tool.commandLine` was received and passed through app.js but **silently ignored** by the renderer — the field existed in the data shape but had no corresponding DOM node. Any refactor of `appendAssistantToolInvocation` must preserve both blocks.

---

## 4. Confirmation/Approval Buttons: Invisible Text

### What it should do
The "Allow" / "Skip" buttons in the confirmation dialog must have **visible text** on any VS Code theme (dark, light, high-contrast).

### Root cause
`.assistant-confirmation-button` CSS had no explicit `color` property. On themes where button background and inherited text color are both dark (or both light), button text becomes invisible.

### Fix
Added `color: var(--vscode-foreground)` and `cursor: pointer` to `.assistant-confirmation-button` in `style.css`.

---

## Bridge Message Checklist

When adding any new bridge message type end-to-end:

| Step | File | What to add |
|------|------|-------------|
| 1 | `src/platform/bridge/vscode-node/conversationBridge.ts` | Emit the message from VS Code side |
| 2 | `pwa/js/app.js` — `handleBridgeMessage()` | Add `case 'turn:X': handleIncomingAssistantX(message); break;` |
| 3 | `pwa/js/app.js` | Define `function handleIncomingAssistantX(message) { ... }` |
| 4 | `pwa/js/chat-renderer.js` | Implement `appendAssistantX(turnId, data)` renderer method |
| 5 | `pwa/css/style.css` | Add styles for any new UI elements |
