#!/bin/bash
# install.sh — lily-agent Setup für Home Assistant
# Lädt alle Komponenten von GitHub — kein base64, kein Blob
#
# Usage:
#   curl -fsSL https://raw.githubusercontent.com/smarthomelily/lily-agent/main/install.sh | bash
#   oder lokal: bash install.sh

set -euo pipefail

GITHUB_RAW="https://raw.githubusercontent.com/smarthomelily/lily-agent/main"
STATE_DIR="/config/.lily-agent"
LOG_DIR="/config/logs/lily-agent"
VERSION=$(curl -sf "${GITHUB_RAW}/VERSION" 2>/dev/null || echo "?")

# Farben
GREEN='\033[0;32m'; RED='\033[0;31m'; YELLOW='\033[1;33m'; NC='\033[0m'
ts()  { echo -e "${GREEN}[$(date '+%H:%M:%S')]${NC} $1"; }
err() { echo -e "${RED}[ERROR]${NC} $1"; }
wrn() { echo -e "${YELLOW}[WARN]${NC} $1"; }

echo ""
echo "════════════════════════════════════════════════════════════"
echo "  lily-agent Setup v${VERSION}"
echo "  github.com/smarthomelily/lily-agent"
echo "════════════════════════════════════════════════════════════"
echo ""

declare -A STATUS

# ── 1. Verzeichnisse ─────────────────────────────────────────────

ts "── Schritt 1: Verzeichnisse"
mkdir -p "$STATE_DIR" "$LOG_DIR" /config/backups /root/.claude
ts "✅ Verzeichnisse erstellt"
STATUS["Verzeichnisse"]="✅"

# ── 2. Telegram konfigurieren ────────────────────────────────────

ts "── Schritt 2: Telegram"

if [[ -f /etc/lily-notify.conf ]]; then
  wrn "lily-notify.conf existiert bereits — wird nicht überschrieben"
  STATUS["Telegram"]="✅ vorhanden"
else
  echo ""
  echo "Telegram Bot Token und Chat ID eingeben."
  echo "Leer lassen + Enter zum Überspringen."
  echo ""
  read -rsp "  Bot Token: " BOT_TOKEN; echo ""
  read -rsp "  Chat ID:   " CHAT_ID; echo ""

  if [[ -n "$BOT_TOKEN" && -n "$CHAT_ID" ]]; then
    cat > /etc/lily-notify.conf << CONF
TELEGRAM_BOT_TOKEN="${BOT_TOKEN}"
TELEGRAM_CHAT_ID="${CHAT_ID}"
CONF
    chmod 600 /etc/lily-notify.conf
    cp /etc/lily-notify.conf "${STATE_DIR}/lily-notify.conf"
    ts "✅ Telegram konfiguriert"
    STATUS["Telegram"]="✅ konfiguriert"
  else
    wrn "Telegram übersprungen — später in /etc/lily-notify.conf eintragen"
    STATUS["Telegram"]="⚠️ nicht konfiguriert"
  fi
fi

# ── 3. Abhängigkeiten ────────────────────────────────────────────

ts "── Schritt 3: Abhängigkeiten"
if ! command -v inotifywait &>/dev/null; then
  apk add --quiet inotify-tools 2>/dev/null && \
    ts "✅ inotify-tools installiert" || wrn "inotify-tools Installation fehlgeschlagen"
else
  ts "✅ inotify-tools vorhanden"
fi
STATUS["Abhängigkeiten"]="✅"

# ── 4. Komponenten von GitHub laden ──────────────────────────────

ts "── Schritt 4: Komponenten herunterladen (v${VERSION})"
echo ""

# Staged install: alles nach tmp laden, dann ins Ziel verschieben
# Verhindert halbfertige Zielzustände bei Download-Fehlern
INSTALL_TMP=$(mktemp -d)
trap "rm -rf ${INSTALL_TMP}" EXIT

COMPONENTS=(
  "lily-agent:/usr/local/bin/lily-agent"
  "CLAUDE.md:/config/CLAUDE.md"
  "SMARTHOMELILY_FRAMEWORK.md:/config/SMARTHOMELILY_FRAMEWORK.md"
)

# settings.json: nur bei Erstinstall — nie still überschreiben
mkdir -p /root/.claude
if [[ ! -f /root/.claude/settings.json ]]; then
  if curl -sf --max-time 15 "${GITHUB_RAW}/settings.json"        -o "${INSTALL_TMP}/settings.json.tmp" 2>/dev/null; then
    mv "${INSTALL_TMP}/settings.json.tmp" /root/.claude/settings.json
    ts "  ✅ settings.json (Initial-Setup)"
    STATUS["Policy"]="✅ Initial-Setup von GitHub"
  else
    err "  settings.json Download fehlgeschlagen — Policy muss manuell gesetzt werden"
    STATUS["Policy"]="⚠️ nicht gesetzt — manuell: lia update --settings"
  fi
else
  ts "  ✅ settings.json existiert bereits — wird nicht überschrieben"
  STATUS["Policy"]="✅ vorhanden (nicht überschrieben)"
fi

for entry in "${COMPONENTS[@]}"; do
  src="${entry%%:*}"
  dst="${entry##*:}"
  tmp_file="${INSTALL_TMP}/${src}"
  if curl -sf --max-time 15 "${GITHUB_RAW}/${src}" -o "$tmp_file" 2>/dev/null; then
    ts "  ✅ ${src} (heruntergeladen)"
  else
    err "  Download fehlgeschlagen: ${src}"
    err "  Bitte manuell herunterladen: ${GITHUB_RAW}/${src}"
    STATUS["Download"]="❌ ${src} fehlgeschlagen"
    exit 1
  fi
done

# Alle Downloads erfolgreich — jetzt Zielinstallation
ts "  Installiere Komponenten..."
for entry in "${COMPONENTS[@]}"; do
  src="${entry%%:*}"
  dst="${entry##*:}"
  mkdir -p "$(dirname "$dst")"
  mv "${INSTALL_TMP}/${src}" "$dst"
  [[ "$src" == "lily-agent" ]] && chmod +x "$dst"
done

STATUS["Download"]="✅ lily-agent, CLAUDE.md, FRAMEWORK"

# ── 4b. system-info.md (Vorlage) ─────────────────────────────────

ts "── system-info.md"
if [[ ! -f /config/system-info.md ]]; then
  curl -sf --max-time 10 "${GITHUB_RAW}/system-info.md"     -o /config/system-info.md 2>/dev/null &&     ts "  ✅ system-info.md Vorlage erstellt — bitte ausfüllen" ||     ts "  ⚠️ system-info.md Download fehlgeschlagen — manuell anlegen"
else
  ts "  ✅ system-info.md bereits vorhanden"
fi

# ── 5. Persistenz-Kopien ─────────────────────────────────────────

ts "── Schritt 5: Persistenz unter ${STATE_DIR}"
cp /usr/local/bin/lily-agent  "${STATE_DIR}/lily-agent"
cp /config/CLAUDE.md              "${STATE_DIR}/CLAUDE.md"
cp /config/SMARTHOMELILY_FRAMEWORK.md "${STATE_DIR}/SMARTHOMELILY_FRAMEWORK.md"
# settings.json: nur persistieren wenn lokal vorhanden
# Wird nach Erstinstall nicht mehr still überschrieben
[[ -f /root/.claude/settings.json ]] &&   cp /root/.claude/settings.json "${STATE_DIR}/settings.json"
echo "$VERSION"                 > "${STATE_DIR}/installed_version"
echo "0"                        > "${STATE_DIR}/last_update_check"  # Nächster Start = Update-Check

[[ -f /etc/lily-notify.conf ]] && \
  cp /etc/lily-notify.conf "${STATE_DIR}/lily-notify.conf"

ts "✅ Persistenz gesichert"
STATUS["Persist"]="✅ ${STATE_DIR}"

# ── 5b. Git-Leak-Schutz (erzwungen) ──────────────────────────────

ts "── Git-Schutz: .gitignore absichern"
if [[ -d /config/.git ]]; then
  for ENTRY in ".lily-agent/" "system-info.md"; do
    if ! grep -qxF "$ENTRY" /config/.gitignore 2>/dev/null; then
      echo "$ENTRY" >> /config/.gitignore
      ts "  ✅ .gitignore: ${ENTRY} hinzugefügt"
    else
      ts "  ✅ .gitignore: ${ENTRY} bereits vorhanden"
    fi
  done
else
  ts "  ℹ️  Kein Git-Repo in /config — .gitignore wird bei git init durch Wrapper gesetzt"
fi

# ── 6. Reinstall-Script ──────────────────────────────────────────

ts "── Schritt 6: Reinstall-Script"
cat > "${STATE_DIR}/reinstall.sh" << 'REINSTALL'
#!/bin/bash
# reinstall.sh — Wird nach jedem HAOS-Neustart automatisch ausgeführt
# Quelle: /config/.lily-agent/ (persistiert)

LOG="/config/logs/lily-agent/reinstall_$(date '+%Y-%m-%d_%H-%M-%S').log"
mkdir -p /config/logs/lily-agent
exec >> "$LOG" 2>&1

echo "[$(date '+%H:%M:%S')] Reinstall gestartet"

STATE_DIR="/config/.lily-agent"
LOG_DIR="/config/logs/lily-agent"

if [[ -f "${STATE_DIR}/lily-agent" ]]; then
  cp "${STATE_DIR}/lily-agent" /usr/local/bin/lily-agent
  chmod +x /usr/local/bin/lily-agent
  echo "[$(date '+%H:%M:%S')] ✅ lily-agent installiert"
fi

if [[ -f "${STATE_DIR}/lily-notify.conf" ]]; then
  cp "${STATE_DIR}/lily-notify.conf" /etc/lily-notify.conf
  chmod 600 /etc/lily-notify.conf
  echo "[$(date '+%H:%M:%S')] ✅ lily-notify.conf installiert"
fi

# settings.json: nur wenn lokal noch nicht vorhanden (Policy nicht überschreiben)
if [[ -f "${STATE_DIR}/settings.json" && ! -f /root/.claude/settings.json ]]; then
  mkdir -p /root/.claude
  cp "${STATE_DIR}/settings.json" /root/.claude/settings.json
  echo "[$(date '+%H:%M:%S')] ✅ settings.json installiert (Initial)"
elif [[ ! -f /root/.claude/settings.json ]]; then
  echo "[$(date '+%H:%M:%S')] ⚠️ settings.json fehlt — bitte manuell setzen oder: lia update --settings"
fi

if ! command -v inotifywait &>/dev/null; then
  apk add --quiet inotify-tools 2>/dev/null && \
    echo "[$(date '+%H:%M:%S')] ✅ inotify-tools installiert" || true
fi

if ! grep -q "# Lily Agent Autostart" /root/.bashrc 2>/dev/null; then
  cat >> /root/.bashrc <<'BASHRC'
alias lia='lily-agent'

# Lily Agent Autostart — nur in interaktiven Shells, kein Doppelstart
if [[ -n "${PS1:-}" && "${LIA_AUTOSTART:-1}" == "1" && -z "${LIA_STARTED:-}" ]]; then
  export LIA_STARTED=1
  lia
fi
BASHRC
fi

VERSION=$(grep "^VERSION=" /usr/local/bin/lily-agent 2>/dev/null | cut -d'"' -f2 || echo "?")
echo "[$(date '+%H:%M:%S')] ✅ Reinstall abgeschlossen — lily-agent v${VERSION}"

# ── Update-Hinweis (informiert, ändert nichts) ────────────────────
REMOTE_VER=$(curl -sf --max-time 5   "https://raw.githubusercontent.com/smarthomelily/lily-agent/main/VERSION"   2>/dev/null | tr -d '[:space:]')

if [[ -n "$REMOTE_VER" && "$REMOTE_VER" != "$VERSION" ]]; then
  echo ""
  echo "[$(date '+%H:%M:%S')] ℹ️  Update verfügbar: v${VERSION} → v${REMOTE_VER}"
  echo "                     Wird automatisch beim nächsten 'lia' geladen."
elif [[ -n "$REMOTE_VER" ]]; then
  echo "[$(date '+%H:%M:%S')] ✅ Aktuell (v${VERSION})"
fi
REINSTALL
chmod +x "${STATE_DIR}/reinstall.sh"
ts "✅ Reinstall-Script erstellt"
STATUS["Reinstall"]="✅"

# ── 7. HA Package (Reinstall + Automation) ───────────────────────

ts "── Schritt 7: HA Package anlegen"

# Packages-Ordner + dedizierte Datei — kein cat >> auf configuration.yaml
mkdir -p /config/packages

PACKAGE_FILE="/config/packages/lily_agent.yaml"
if [[ ! -f "$PACKAGE_FILE" ]]; then
  cat > "$PACKAGE_FILE" << 'YAML'
# lily-agent — automatisch generiert, nicht manuell bearbeiten
# Quelle: github.com/smarthomelily/lily-agent

shell_command:
  lily_reinstall: "bash /config/.lily-agent/reinstall.sh"

automation:
  - id: "lily_agent_reinstall_on_start"
    alias: "System: Lily Agent nach Neustart reinstallieren"
    description: "Stellt lily-agent nach jedem HAOS-Neustart wieder her"
    triggers:
      - trigger: homeassistant
        event: start
    actions:
      - action: shell_command.lily_reinstall
    mode: single
YAML
  ts "✅ Package erstellt: ${PACKAGE_FILE}"
else
  ts "✅ Package bereits vorhanden"
fi

# Prüfen ob packages in configuration.yaml aktiviert ist
if ! grep -q "packages" /config/configuration.yaml 2>/dev/null; then
  wrn "Packages noch nicht in configuration.yaml aktiviert."
  wrn "Bitte eintragen unter 'homeassistant:':"
  echo ""
  echo "    homeassistant:"
  echo "      packages: !include_dir_named packages"
  echo ""
  STATUS["HA-Automation"]="⚠️ packages aktivieren"
else
  ts "✅ packages bereits in configuration.yaml"
  STATUS["HA-Automation"]="✅"
fi

# ── 8. Alias ─────────────────────────────────────────────────────

if ! grep -q "# Lily Agent Autostart" /root/.bashrc 2>/dev/null; then
  cat >> /root/.bashrc <<'BASHRC'
alias lia='lily-agent'

# Lily Agent Autostart — nur in interaktiven Shells, kein Doppelstart
if [[ -n "${PS1:-}" && "${LIA_AUTOSTART:-1}" == "1" && -z "${LIA_STARTED:-}" ]]; then
  export LIA_STARTED=1
  lia
fi
BASHRC
  ts "✅ Alias + Autostart eingetragen"
fi
STATUS["Alias"]="✅"

# ── 9. Config-Check ──────────────────────────────────────────────

ts "── Schritt 8: Config-Check"
if [[ -z "${SUPERVISOR_TOKEN:-}" ]]; then
  wrn "SUPERVISOR_TOKEN nicht gesetzt — Config-Check übersprungen"
  STATUS["Config-Check"]="⚠️ übersprungen (kein Token)"
else
  CHECK=$(curl -s -X POST \
    -H "Authorization: Bearer ${SUPERVISOR_TOKEN}" \
    http://supervisor/core/check 2>/dev/null || echo '{"result":"unknown"}')
  if echo "$CHECK" | grep -q '"result":"ok"'; then
    ts "✅ HA Config: OK"
    STATUS["Config-Check"]="✅"
  else
    wrn "Config-Check: ${CHECK}"
    STATUS["Config-Check"]="⚠️ prüfen"
  fi
fi

# ── Zusammenfassung ──────────────────────────────────────────────

echo ""
echo "════════════════════════════════════════════════════════════"
echo "  Setup abgeschlossen — lily-agent v${VERSION}"
echo "════════════════════════════════════════════════════════════"
echo ""
for key in "Verzeichnisse" "Telegram" "Abhängigkeiten" "Download" "Policy" "Persist" "Reinstall" "HA-Automation" "Alias" "Config-Check"; do
  printf "  %-20s %s\n" "${key}:" "${STATUS[$key]:-—}"
done
echo ""
echo "  Verwendung:"
echo "    source /root/.bashrc"
echo "    lia                   → Lily Agent starten"
echo "    lia backup            → Pre-Session Backup"
echo ""
echo "  Auto-Update: täglich von github.com/smarthomelily/lily-agent"
echo ""
