# Conclave installer for Windows (needs Docker Desktop with the WSL2 engine).
#   irm https://raw.githubusercontent.com/MVSanjayNiranjan/conclave/main/install.ps1 | iex
# Installs into %USERPROFILE%\conclave (override with $env:CONCLAVE_DIR).
$ErrorActionPreference = 'Stop'

$RepoRaw = 'https://raw.githubusercontent.com/MVSanjayNiranjan/conclave/main'
$Dir = if ($env:CONCLAVE_DIR) { $env:CONCLAVE_DIR } else { Join-Path $HOME 'conclave' }
$Url = 'http://localhost:7700'

function Say($m) { Write-Host "==> $m" -ForegroundColor Magenta }
function Fail($m) { Write-Host "Error: $m" -ForegroundColor Red; exit 1 }
function Ask($q) { $a = Read-Host "$q [Y/n]"; return -not ($a -match '^(n|no)$') }

if (-not (Get-Command docker -ErrorAction SilentlyContinue)) {
  Fail "Docker is not installed. Install Docker Desktop from https://www.docker.com/products/docker-desktop/ (keep 'Use WSL 2' checked) and run this again."
}
docker info *> $null
if ($LASTEXITCODE -ne 0) { Fail "Docker is installed but not running. Start Docker Desktop, wait until it says it's running, and run this again." }
docker compose version *> $null
if ($LASTEXITCODE -ne 0) { Fail "Your Docker has no 'docker compose'. Update Docker Desktop and run this again." }

Say "Installing Conclave into $Dir"
New-Item -ItemType Directory -Force -Path $Dir | Out-Null
Set-Location $Dir
Invoke-WebRequest -UseBasicParsing "$RepoRaw/docker-compose.yml" -OutFile 'docker-compose.yml'

# Where projects go. Agents can only see this folder, so pick an empty or dedicated one.
$DefaultWs = Join-Path $Dir 'workspace'
$Ws = Read-Host "Folder for your projects [$DefaultWs]"
if (-not $Ws) { $Ws = $DefaultWs }
New-Item -ItemType Directory -Force -Path $Ws | Out-Null
$Ws = (Resolve-Path $Ws).Path -replace '\\', '/'
Set-Content -Path '.env' -Encoding ascii -Value "CONCLAVE_WORKSPACE_DIR=$Ws`nCONCLAVE_HOST_WORKSPACE=$Ws"
Say "Projects will be saved in $Ws"

Say 'Downloading Conclave (first time only, a few hundred MB)'
docker compose pull
if ($LASTEXITCODE -ne 0) { Fail 'Download failed. Check your internet connection and try again.' }
docker compose up -d
if ($LASTEXITCODE -ne 0) { Fail "Conclave didn't start. If port 7700 is in use, stop whatever uses it and try again." }

Say 'First start: installing Claude Code, Codex CLI and Copilot CLI inside the container (about a minute)'
$i = 0
while ($true) {
  docker compose exec -T conclave test -f /opt/conclave-tools/.installed *> $null
  if ($LASTEXITCODE -eq 0) { break }
  $i++
  if ($i -gt 120) { Fail "The agent CLIs didn't finish installing. Check 'docker compose logs conclave'." }
  Start-Sleep -Seconds 2
}

Say "Sign in to the agents you have subscriptions for (once; you can skip any and do it later)."
if (Ask 'Sign in to Claude Code now? (type /login, follow the link, then /exit)') { docker compose exec conclave claude }
if (Ask 'Sign in to Codex (ChatGPT) now?') { docker compose exec conclave codex login --device-auth }
if (Ask 'Sign in to GitHub Copilot now?') { docker compose exec conclave copilot login --device-code }

Say "Conclave is running at $Url"
Start-Process $Url
Write-Host ""
Write-Host "  Your projects:  $Ws"
Write-Host "  Stop:           cd $Dir; docker compose down"
Write-Host "  Update:         cd $Dir; docker compose pull; docker compose up -d"
