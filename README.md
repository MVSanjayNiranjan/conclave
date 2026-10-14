# Conclave

**One prompt in, a tested project out.** Conclave runs Claude Code, Codex CLI and GitHub Copilot CLI as one team on your own computer, using your own subscriptions. You describe what you want in one sentence. A Director agent plans it, coder agents build each piece tests-first, and the test suite decides when it's done. A live dashboard shows every step, and you can change who does what while it runs.

![Conclave dashboard](docs/dashboard.png)

- **Plans before it builds.** A brief with goals and assumptions, and a task graph where each task has acceptance criteria and the tests that prove it.
- **Tests decide.** Coders write tests first, and a failing task goes to a fixer agent, up to three tries.
- **Your team, your choice.** Pick the Director, the coders (one, or several taking turns) and the fixer, and change them mid-run.
- **Pick the model.** Choose each agent's model and reasoning effort from its live model list, and change them mid-run. Models your plan doesn't include are detected and marked, and runs fall back to the default automatically.
- **Extensions, like VS Code.** Browse and install thousands of plugins from each agent's own marketplace: Claude's official directory, Copilot's awesome-copilot, and Codex's catalog.
- **Connectors.** Search the official MCP Registry and add servers (GitHub, databases, docs lookup and more) in one click.
- **Your projects, your editor.** Choose where projects are saved, open any project in VS Code with one click, and delete runs you don't need.
- **Serial or parallel.** Independent tasks can be built side by side, each in its own git branch, and merged when green.
- **See everything.** A live task graph, each agent's output, diffs, the brief and report in a full-screen reader, and a token dashboard showing what each agent used.
- **Safe by default.** Agents work inside a Docker container that only sees your projects folder. See [SECURITY.md](SECURITY.md).

## What you need

- **Docker Desktop** (Windows, macOS) or Docker Engine (Linux). On Windows, use the WSL 2 engine.
- **At least one of these subscriptions.** Conclave uses your own logins and never shares them:
  - **Claude** (Pro or Max) for Claude Code, the default Director
  - **ChatGPT** (Plus, Pro or Team) for Codex, the default coder and fixer
  - **GitHub Copilot** for Copilot CLI
- About 2 GB of free disk space.

With only one subscription, set every role to that agent when you start a run.

## Install

**Windows** (PowerShell):

```powershell
irm https://raw.githubusercontent.com/MVSanjayNiranjan/conclave/main/install.ps1 | iex
```

**macOS / Linux**:

```bash
curl -fsSL https://raw.githubusercontent.com/MVSanjayNiranjan/conclave/main/install.sh | sh
```

The installer:
- checks Docker
- asks where to save your projects (default: a `workspace` folder inside `conclave`)
- downloads Conclave into a `conclave` folder in your home directory
- starts it
- installs the three agent CLIs from their official sources
- walks you through signing in (once)
- opens **http://localhost:7700**

<details>
<summary>Prefer to do it by hand?</summary>

1. Make a folder and save [`docker-compose.yml`](docker-compose.yml) in it.
2. In that folder, start Conclave:

```bash
docker compose up -d
```

3. Sign in to each agent you use (once):

```bash
docker compose exec conclave claude
```
In Claude Code, type `/login`, follow the link, then `/exit`.

```bash
docker compose exec conclave codex login --device-auth
```

```bash
docker compose exec conclave copilot login --device-code
```

4. Open http://localhost:7700.
</details>

## Your first run

1. Click **New run**.
2. Describe the project, for example *"Build a Python CLI that converts CSV to JSON, with pytest tests"*.
3. Pick the team and the build mode (Serial, or Parallel ×2), and start.
4. Watch it work. The project appears in your projects folder as a normal git repository, with one commit per step. Leave the folder name blank and Conclave names it from your prompt (for example `ledger`).
5. When it's done, click **Open in VS Code** under the title to run, debug or edit it.

The roles bar changes the team for the next step, even mid-run. Its **Models** button sets each agent's model and reasoning effort. The lists come live from each CLI: Codex shows the effort levels each model supports, and Copilot lists every model your plan offers. Click a task in the graph to see its tests, its diff, pin it to a specific coder, retry it or skip it.

## The dashboard

The layout works like VS Code:

| Shortcut | Action |
|---|---|
| `Ctrl+B` | Show or hide the runs sidebar |
| `Ctrl+Alt+B` | Show or hide the token panel |
| `Ctrl+J` | Show or hide the agents panel |
| `Alt+N` | New run |
| `Alt+R` | Open the brief or report in the full-screen reader |
| `Esc` | Close the reader or a dialog |
| `?` | All shortcuts |

Drag any divider to resize. Drag a panel past its edge to tuck it away, then bring it back with its shortcut. The layout is remembered.

The **token panel** shows tokens for this run, the last 7 days or all time:
- broken down by agent, by role and by step, with a per-day chart
- Claude's reported cost
- Copilot's premium requests

## Extensions and connectors

**Extensions** (puzzle icon) work like VS Code's Extensions view:
- Pick an agent (Claude, Codex or Copilot) and search its marketplaces.
- Click **Install** or **Uninstall**, or open an extension to see its details and source.
- Add more marketplaces at the bottom of the list.

Extensions are installed with each CLI's own `plugin` command, so they behave exactly as they do in that CLI, and they load in every later agent step.

**Connectors** (plug icon) are MCP servers that give agents extra tools:
- **Marketplace** tab: search the official MCP Registry and click **Add**. The form comes prefilled with the pinned package and the settings it needs. Fill in any keys it asks for.
- **Installed** tab: switch connectors on or off, choose which agents get each one, or start from a recommended preset (Context7 docs, Sequential thinking, Memory, GitHub).
- API keys and tokens are stored locally, never shown again, and never written to logs.

Extensions and connectors are third-party code that runs inside the container. Add only ones you trust, and check the source link.

## Your projects

- **Where they're saved:** the folder you chose during install. Settings (gear icon) shows it.
- **Open in VS Code:** the link under each run's title, or **⋯ → Open in VS Code** in the Runs list. Use VS Code's terminal to run the project; the brief's "How to run" section has the commands.
- **Delete:** **⋯ → Delete…** in the Runs list. You can remove the run from the dashboard and keep its files, or delete the project folder too (you'll be asked to type its name).
- **Change the folder:** edit `.env` next to `docker-compose.yml`:

```
CONCLAVE_WORKSPACE_DIR=D:/Projects
CONCLAVE_HOST_WORKSPACE=D:/Projects
```

Then run `docker compose up -d`. Agents can only see this folder, so don't choose one with private files.

## Choosing models

Open **Models** in the roles bar (or in New run) to set each agent's model and reasoning effort. The lists come from each CLI.

The CLIs can't tell Conclave which models your plan includes. So:
- **Check** next to a model asks the CLI whether it works for you (one tiny request).
- If a run uses a model your plan doesn't include, Conclave notices, marks it **not on your plan**, and switches that step to the default model.
- If a model doesn't take a reasoning effort (like Copilot's **Auto**), the effort setting is disabled and never sent.

## Everyday commands

Run these in your `conclave` folder:

| What | Command |
|---|---|
| Stop | `docker compose down` (projects, logins and history are kept) |
| Start again | `docker compose up -d` |
| Update to the latest version | `docker compose pull && docker compose up -d` |
| Start a run from the terminal | `docker compose exec conclave conclave run "your prompt" -p folder-name` |
| Check the agent CLIs | `docker compose exec conclave conclave doctor` |

## Your data

Everything runs on your computer.
- Your projects stay in `workspace/`.
- Run history and logins stay in Docker volumes.
- The agents send your project's code to their own providers (Anthropic, OpenAI, GitHub) as part of normal use, under each provider's terms.
- Conclave itself sends nothing anywhere.

## Troubleshooting

- **"Docker is installed but not running".** Start Docker Desktop and wait until it says it's running.
- **WSL errors on Windows** ("Class not registered", `REGDB_E_CLASSNOTREG`). In an Administrator PowerShell, run these, restart, then install Docker Desktop:

```powershell
dism.exe /online /enable-feature /featurename:Microsoft-Windows-Subsystem-Linux /all /norestart
```
```powershell
dism.exe /online /enable-feature /featurename:VirtualMachinePlatform /all /norestart
```
```powershell
wsl --install --web-download --no-distribution
```
- **Port 7700 is already in use.** In `docker-compose.yml`, change `127.0.0.1:7700:7700` to `127.0.0.1:7800:7700` and open http://localhost:7800.
- **An agent says it isn't signed in.** Run its sign-in command from [Install](#install) again.
- **A run stopped on a usage limit.** It pauses and resumes when you click **Resume** after the limit resets.
- **You deleted the Docker container.** Nothing is lost: projects, logins and history live outside it. Run `docker compose up -d` to recreate it. Only `docker compose down -v` (with `-v`) deletes logins and history.
- **A model shows "not on your plan".** Pick another model, or choose **Default model**.
- **Open in VS Code does nothing.** Install VS Code, and check that Settings shows your projects folder. If it doesn't, add `CONCLAVE_HOST_WORKSPACE` to `.env` as shown above.

## Security

See [SECURITY.md](SECURITY.md) for what's protected, what isn't, and how to report a vulnerability privately.

## License

Free to use, personally or commercially. Copying, modifying, redistributing and reverse-engineering are not allowed. See [LICENSE](LICENSE). Claude Code, Codex CLI and Copilot CLI are third-party tools under their own terms.
