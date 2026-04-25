---
name: remote-claw
description: Send prompts and commands to a remote OpenClaw instance via SSH tunnel + HTTP API. Use when the user wants to offload a coding task, ask the remote machine to run something, check remote status, or delegate work.
---

# Remote OpenClaw Bridge

Communicate with a remote OpenClaw instance over an SSH tunnel. The remote gateway speaks an OpenAI-compatible HTTP API on port 18789.

## Setup

Verify SSH access works (one-time):

```bash
ssh -o ConnectTimeout=5 wkwkwk.ngrok.app "openclaw gateway status"
```

If that fails, check the remote hostname and that OpenClaw gateway is running.

## Workflow

### 1. Establish tunnel

```bash
# Check if tunnel is already up
lsof -i :18789 2>/dev/null | grep LISTEN

# If not, bring it up (background, port forward 18789)
ssh -f -N -M -S /tmp/remote-claw-ctrl -L 18789:127.0.0.1:18789 wkwkwk.ngrok.app
```

The `-M -S` creates a control socket at `/tmp/remote-claw-ctrl` so you can kill the tunnel later without hunting PIDs.

### 2. Send a prompt

```bash
curl -s -N http://localhost:18789/v1/chat/completions \
  -H "Content-Type: application/json" \
  -d '{
    "model": "openclaw:main",
    "stream": false,
    "messages": [{"role": "user", "content": "PROMPT HERE"}]
  }' | jq -r '.choices[0].message.content // .'
```

For **streaming** (live output as the remote agent works):

```bash
curl -s -N --no-buffer http://localhost:18789/v1/chat/completions \
  -H "Content-Type: application/json" \
  -d '{
    "model": "openclaw:main",
    "stream": true,
    "messages": [{"role": "user", "content": "PROMPT HERE"}]
  }'
```

### 3. Send a command (less chatty — just run something on the remote)

```bash
# Prompt OpenClaw to exec a command and return only the result
curl -s http://localhost:18789/v1/chat/completions \
  -H "Content-Type: application/json" \
  -d '{
    "model": "openclaw:main",
    "stream": false,
    "messages": [{"role": "user", "content": "Run this shell command and return only stdout: COMMAND"}]
  }' | jq -r '.choices[0].message.content // .'
```

### 4. Check remote status

```bash
ssh -o ConnectTimeout=5 wkwkwk.ngrok.app "openclaw gateway status; echo '---'; uptime; df -h / | tail -1"
```

### 5. Tear down tunnel

```bash
# Graceful close via control socket
ssh -S /tmp/remote-claw-ctrl -O exit wkwkwk.ngrok.app 2>/dev/null

# Or force-kill
pkill -f "ssh.*-L 18789.*wkwkwk.ngrok.app"
```

## Rendering rules

- Always state whether the tunnel is up before sending prompts.
- For streaming responses, show content as it arrives (don't buffer).
- If curl returns empty or errors (`jq: parse error`, HTTP 404, `Connection refused`), tell the user: the remote gateway may not have HTTP endpoints enabled. Check `gateway.http.endpoints.chatCompletions.enabled` in `~/.openclaw/openclaw.json` on the remote.
- If SSH times out or connection is refused, ngrok tunnel may be down — tell the user to restart it on the remote.

## Prompts best practices

- Be explicit: "run `git status` in `~/projects/foo`" not "what's up with git".
- Prefer non-streaming for simple commands (`stream: false`), streaming for coding tasks.
- The remote OpenClaw has its own skills and tools — you're delegating, not remote-executing raw bash.
