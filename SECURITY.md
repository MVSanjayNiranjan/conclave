# Security

Conclave runs AI coding agents that write and execute code on your machine. This page explains what keeps that contained, what it doesn't protect against, and how to report a problem.

## How Conclave is contained

| Area | What Conclave does |
|---|---|
| **Sandbox** | Agents run inside one Docker container. They can only see `./workspace` (your projects) and their own login volumes. They can't see the rest of your files. |
| **Dashboard access** | The dashboard is published on `127.0.0.1:7700` only, so other machines on your network can't reach it. |
| **Browser attacks** | The server answers only requests addressed to `localhost`, which blocks DNS rebinding. It accepts writes and WebSocket connections only from its own pages, which blocks cross-site requests. |
| **Headers** | Every response carries a strict Content-Security-Policy, `X-Frame-Options: DENY`, `nosniff` and `no-referrer`. |
| **Agent text** | Briefs, reports and logs written by agents are shown as text or sanitized markdown. Raw HTML is never rendered, so agent output can't run scripts in your browser. |
| **Credentials** | Each CLI stores its own login token in its own Docker volume. Conclave never reads, copies or sends those tokens. Nothing is uploaded anywhere except what each agent CLI sends to its own provider. |
| **Agent permissions** | **Claude Code:** edits and a fixed tool list are allowed, and anything else that would prompt is denied. **Copilot CLI:** path checks stay on, its built-in GitHub MCP server is disabled, and `git push` / `rebase` / `reset` are denied. **Codex:** uses its "externally sandboxed" mode only inside the container, and Conclave refuses that mode anywhere else. |
| **Connector secrets** | API keys and tokens you give connectors are stored in Conclave's local database (its Docker volume). The API returns only their names, never their values. Each step gets them through a private file (mode 0600) that's deleted when the step ends. Where a CLI only takes them as arguments (Codex), they're masked as `***` in the raw logs. |
| **Model choice** | Model ids and effort levels are checked against a strict allowlist before they reach a command line. |
| **Marketplaces** | Extension lists come from each CLI's own marketplaces; connector search comes from the official MCP Registry. Registry packages are pinned to the listed version, plain-http remotes are refused, and Docker-only servers aren't offered. |
| **Deleting projects** | Deleting a project folder needs typing its name, only works for folders inside the projects folder (symlinks resolved), and refuses folders another run still uses. |
| **Plugins** | Each CLI's own `plugin` command is run with fixed arguments and no shell. Plugin names that could be read as flags or shell syntax are refused. |
| **Git history** | Every agent step is a commit. A merge that breaks the tests is undone with a new revert commit; history is never rewritten. Nothing is pushed anywhere. |
| **Supply chain** | The agent CLIs are installed from their official npm packages at pinned versions. The Conclave image is built in CI from a pinned base image. |

## What it does not protect against

- **Your projects are writable by agents.** Anything inside `./workspace` can be changed or deleted by an agent. Keep important work in git and pushed somewhere else.
- **Network access is on**, because agents need package registries. A misbehaving agent could download things or contact websites from inside the container.
- **Agents send your project code to their providers** (Anthropic, OpenAI, GitHub) as part of normal operation, under each provider's terms. Don't put secrets you can't share with those providers in `./workspace`.
- **Marketplace entries are third-party.** Anyone can publish to the plugin marketplaces and the MCP Registry. Check an entry's source before installing it.
- **Connectors and plugins run code.** An MCP server or plugin runs inside the container with the agents' access. A malicious one could read or change your projects or use the network. Add only ones you trust, and pin versions.
- **Connector secrets are not encrypted at rest.** They sit in the local database inside the Docker volume. Anyone who can read that volume can read them. Use tokens with the least access you can.
- **The dashboard has no login.** Anyone who can use your computer's browser can use it. Don't change the port binding to `0.0.0.0` on a shared or untrusted network.
- **Docker itself.** The container is a strong boundary, but not a virtual machine. Keep Docker Desktop updated.

## Good practice

- Keep secrets (API keys, `.env` files) out of `./workspace`. If tests need them, use dummy values.
- Review an agent's diff (dashboard → task → Diff) before you rely on or ship the code.
- Update regularly with `docker compose pull && docker compose up -d`.

## Reporting a vulnerability

Please **don't open a public issue** for security problems. Instead, use GitHub's private reporting: go to the repository's **Security** tab and choose **Report a vulnerability**. You'll get a reply within 7 days.
