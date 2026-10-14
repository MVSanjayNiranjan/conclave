#!/bin/sh
# Conclave installer for macOS and Linux.
#   curl -fsSL https://raw.githubusercontent.com/MVSanjayNiranjan/conclave/main/install.sh | sh
# Installs into ~/conclave (override with CONCLAVE_DIR=/path).
set -eu

REPO_RAW="https://raw.githubusercontent.com/MVSanjayNiranjan/conclave/main"
DIR="${CONCLAVE_DIR:-$HOME/conclave}"
URL="http://localhost:7700"

say() { printf '\033[1;35m==>\033[0m %s\n' "$*"; }
fail() { printf '\033[1;31mError:\033[0m %s\n' "$*" >&2; exit 1; }
ask() { # ask "question" -> 0 for yes (default yes)
  printf '%s [Y/n] ' "$1"
  read -r a </dev/tty || a=""
  case "$a" in n|N|no|No) return 1 ;; *) return 0 ;; esac
}

command -v docker >/dev/null 2>&1 || fail "Docker is not installed. Install Docker Desktop from https://www.docker.com/products/docker-desktop/ and run this again."
docker info >/dev/null 2>&1 || fail "Docker is installed but not running. Start Docker Desktop, wait until it says it's running, and run this again."
docker compose version >/dev/null 2>&1 || fail "Your Docker has no 'docker compose'. Update Docker Desktop and run this again."

say "Installing Conclave into $DIR"
mkdir -p "$DIR/workspace"
cd "$DIR"
curl -fsSL "$REPO_RAW/docker-compose.yml" -o docker-compose.yml

if [ "$(uname -s)" = "Linux" ] && [ "$(id -u)" != "1000" ]; then
  say "Note: Conclave runs as user id 1000 inside the container; making $DIR/workspace writable for it."
  chmod 777 "$DIR/workspace" 2>/dev/null || true
fi

say "Downloading Conclave (first time only, a few hundred MB)"
docker compose pull
docker compose up -d

say "First start: installing Claude Code, Codex CLI and Copilot CLI inside the container (about a minute)"
i=0
until docker compose exec -T conclave test -f /opt/conclave-tools/.installed 2>/dev/null; do
  i=$((i + 1)); [ "$i" -gt 120 ] && fail "The agent CLIs didn't finish installing. Check 'docker compose logs conclave'."
  sleep 2
done

say "Sign in to the agents you have subscriptions for (once; you can skip any and do it later)."
if ask "Sign in to Claude Code now? (type /login, follow the link, then /exit)"; then
  docker compose exec conclave claude </dev/tty || true
fi
if ask "Sign in to Codex (ChatGPT) now?"; then
  docker compose exec conclave codex login --device-auth </dev/tty || true
fi
if ask "Sign in to GitHub Copilot now?"; then
  docker compose exec conclave copilot login --device-code </dev/tty || true
fi

say "Conclave is running at $URL"
( command -v open >/dev/null 2>&1 && open "$URL" ) || ( command -v xdg-open >/dev/null 2>&1 && xdg-open "$URL" >/dev/null 2>&1 ) || true
echo
echo "  Your projects:  $DIR/workspace"
echo "  Stop:           cd $DIR && docker compose down"
echo "  Update:         cd $DIR && docker compose pull && docker compose up -d"
