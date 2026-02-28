# Changelog — lily-agent

Format: `MAJOR.MINOR.PATCH`
- **MAJOR** — Breaking changes (Pfade, Struktur, Verhalten)
- **MINOR** — Neue Features, neue Komponenten
- **PATCH** — Bugfixes, Anpassungen ohne Verhaltensänderung

---

## [1.7.1] — 2025-03-01

### Bugfix (Blocker)
- Alpine Linux Kompatibilität: `/root/.bashrc` existiert nicht auf HAOS
- Alias + Autostart werden jetzt in `/etc/profile.d/lily-agent.sh` geschrieben
- `[[ ]]` → `[ ]` im Autostart-Block (ash-kompatibel)
- Gilt für Installer (Schritt 8) und reinstall.sh

---

## [1.7.0] — 2025-03-01

### Neu
- `lia setup` — interaktiver Telegram + Hostname Konfigurator mit Testnachricht
  - Zeigt aktuellen Hostname an, erlaubt Überschreiben
  - Bestehende Werte bleiben erhalten (Enter zum Behalten)
  - Schickt Testnachricht und zeigt Ergebnis
- Installer: Telegram-Eingabe entfernt — kein Blockieren mehr bei `curl | bash`
- Installer: Hinweis auf `lia setup` in Zusammenfassung

---

## [1.6.8] — 2025-03-01

### Neu
- `HOSTNAME_OVERRIDE` in `/etc/lily-notify.conf` — überschreibt den automatisch erkannten Hostname in allen Telegram-Nachrichten

---

## [1.6.7] — 2025-03-01

### Fixes
- `.bashrc` Autostart-Check: Marker `# Lily Agent Autostart` statt `alias lia=` — Block wird auch nachgerüstet wenn nur Alias aber kein Autostart vorhanden
- CHANGELOG 1.6.6: Verhalten von `source /root/.bashrc` korrekt beschrieben

---

## [1.6.6] — 2025-03-01

### Bugfix
- Autostart: `echo "lia" >> .bashrc` ersetzt durch guarded Block
- `PS1`-Check: startet nur in interaktiven Shells
- `LIA_AUTOSTART`: per `LIA_AUTOSTART=0` deaktivierbar
- `LIA_STARTED`: verhindert Doppelstart in derselben Session
- `source /root/.bashrc` ohne gesetztes `LIA_STARTED` startet den Agenten — bewusstes Verhalten in interaktiven Shells

---

## [1.6.5] — 2025-03-01

### Neu
- Autostart: `lia` wird in `.bashrc` eingetragen — Terminal öffnen startet Lily Agent automatisch
- Gilt sowohl beim Erstinstall als auch nach jedem HAOS-Neustart via `reinstall.sh`

---

## [1.6.4] — 2025-03-01

### Änderungen
- README: Tagline "Claude Code Deployment & Operations" → "Managed agent runtime for Home Assistant" (providerneutral)

### Bekannte Einschränkungen
- `lily_agent.yaml` (HA-Package) wird nur beim Erstinstall angelegt — spätere Änderungen kommen bei bestehenden Installationen nicht automatisch an. Geplant für v2.

---

## [1.6.3] — 2025-03-01

### Neu
- `system-info.md` Vorlage im Repo — wird beim Install automatisch nach `/config/system-info.md` geladen
- Enthält: Basis, Integrationen, Hardware-Eigenheiten, Bekannte Probleme, Letzte Sessions
- Idempotent: existierende Datei wird nicht überschrieben

### Bestätigt
- Alias-Idempotenz in `reinstall.sh` war bereits korrekt implementiert (`if ! grep -q`)

---

## [1.6.2] — 2025-03-01

### Bugfix (Blocker)
- `LOG_DIR` in `install.sh` fehlte — Script wäre bei `set -euo pipefail` sofort abgestürzt

---

## [1.6.1] — 2025-03-01

### Fixes
- `LOG_DIR` Deklaration wiederhergestellt — fehlte nach Umbenennung, hätte Script beim Start abgebrochen
- HA-Automation alias: "Claude Code" → "Lily Agent"
- Legacy-Alias `cm` vollständig entfernt — `lia` ist einziger Befehl
- settings.json Kommentar präzisiert

---

## [1.6.0] — 2025-03-01

### Breaking Change: Vollständige Umbenennung claude-* → lily-*
- Binary: `/usr/local/bin/claude-managed` → `/usr/local/bin/lily-agent`
- State-Dir: `/config/.claude-managed` → `/config/.lily-agent`
- Logs: `/config/logs/claude` → `/config/logs/lily-agent`
- Notify-Config: `/etc/claude-notify.conf` → `/etc/lily-notify.conf`
- HA-Package: `claude_managed.yaml` → `lily_agent.yaml`
- Shell-Command: `claude_reinstall` → `lily_reinstall`
- Automation-ID: `claude_managed_reinstall_on_start` → `lily_agent_reinstall_on_start`
- Persistenz-Datei: `claude-managed` → `lily-agent`
- Alias: `lia` (primär) + `cm` (Legacy-Kompatibilität)
- Addon-Slug-Erkennung: sucht jetzt nach `lily` und `claude`
- settings.json: Binary- und Notify-Pfade aktualisiert

---

## [1.5.1] — 2025-03-01

### Polish
- Summary: feste Schlüssel-Reihenfolge statt zufälliger `${!STATUS[@]}` Iteration
- Fehlender Key zeigt `—` statt leerem Eintrag
- `LOG_DIR` Deklaration im Installer entfernt (wurde nicht genutzt)

---

## [1.5.0] — 2025-03-01

### Neu
- **Git-Leak-Schutz im Installer**: `.gitignore` wird beim Install direkt geprüft und um `.lily-agent/` + `system-info.md` ergänzt — falls noch kein Git-Repo vorhanden, übernimmt der Wrapper das beim ersten `git init`
- **Ehrlicher Update-Check in `reinstall.sh`**: nach jedem HAOS-Neustart wird GitHub-Version geprüft und ein Hinweis ausgegeben wenn Update verfügbar (`v1.4.x → v1.5.0`) — kein Auto-Update, kein Code-Eingriff, nur Information

---

## [1.4.5] — 2025-03-01

### Polish
- Config-Check im Installer: läuft nur wenn `SUPERVISOR_TOKEN` gesetzt ist, sonst `STATUS["Config-Check"]="⚠️ übersprungen (kein Token)"`
- Kommentar "staged install ... atomisch verschieben" → präziser: "ins Ziel verschieben / verhindert halbfertige Zielzustände"

---

## [1.4.4] — 2025-03-01

### Klarheit
- Summary: `STATUS["Policy"]` jetzt explizit — ✅ vorhanden / ✅ Initial-Setup / ⚠️ nicht gesetzt
- `STATUS["Download"]` zeigt jetzt nur die 3 Kern-Komponenten — Policy-Status separat sichtbar
- Kommentar "atomisch" → "staged download, dann Zielinstallation" (Garantie korrekt benannt)

---

## [1.4.3] — 2025-03-01

### Sicherheit (kritisch)
- `settings.json` vollständig aus dem automatischen Install-Prozess entfernt
- Install: `settings.json` wird **nur bei Erstinstall** von GitHub geholt (`! -f /root/.claude/settings.json`)
- Existierende Policy wird nie still überschrieben
- Persistenz: `settings.json` nur kopieren wenn lokal vorhanden (`[[ -f ... ]] && cp`)
- Reinstall: `settings.json` nur wiederherstellen wenn `/root/.claude/settings.json` noch nicht existiert
- `INSTALL_TMP=$(mktemp -d)` vor den Download-Blöcken verschoben (war undefiniert bei settings.json-Download)

### Semantik jetzt korrekt
1. Erstinstall → Default-Policy von GitHub (einmalig)
2. Spätere Installs/Updates → Policy bleibt lokal unberührt
3. Neustart-Reinstall → Policy nur wenn komplett fehlend
4. Manuelles Update → `cm update --settings` mit expliziter Bestätigung

---

## [1.4.2] — 2025-03-01

### Bugfixes
- **Bug**: `cm update --settings` referenzierte `${GITHUB_RAW}` bevor die Variable definiert war → leere URL + fehlgeschlagener Download. Fix: lokale `_RAW` Variable im Subcommand
- **Bug**: Dateiliste in Telegram-Ende-Nachricht endete immer mit `/` durch falsches `sed 's/ $/\/'`. Fix: `sed 's/ $//'`

### Cleanup
- Header-Kommentar: "45 Min" → "10 Min" (war seit Timeout-Reduktion veraltet)
- `abort=0` toter Code aus `check_system_health()` entfernt (Variable wurde nie ausgewertet)
- Pre-Flight Telegram-Nachrichten auf kompaktes Einzeiler-Format vereinheitlicht (konsistent mit Start/Ende/Idle)

---

## [1.4.1] — 2025-03-01

### Sicherheit
- `settings.json` aus Auto-Update entfernt — Security-Policy wird nicht mehr automatisch remote überschrieben
- Neuer Subcommand `cm update --settings` für manuelles Policy-Update mit expliziter Bestätigung

### Robustheit
- Install-Script: Downloads jetzt atomisch via `mktemp -d` + `mv` — kein halbfertiger Zustand bei Abbruch
- `trap` stellt sicher dass tmp-Verzeichnis auch bei Fehler bereinigt wird

### UX
- Token-Eingabe im Installer jetzt mit `read -rsp` — kein Klartext auf dem Bildschirm

---

## [1.4.0] — 2025-03-01

### Sicherheit
- **Config-Check Guard**: Kein Git-Commit bei ungültigem HA-Config-Check — verhindert Commit von kaputten YAML-States
- Telegram-Warnung `🚨` wenn Config-Check fehlschlägt
- `git reset HEAD` bei fehlgeschlagenem Check — keine staged Changes

### Architektur
- **Packages statt `cat >>`**: `shell_command` + `automation` in `/config/packages/lily_agent.yaml`
- Kein direktes Beschreiben von `configuration.yaml` oder `automations.yaml` mehr
- Installer prüft ob `packages:` in `configuration.yaml` aktiviert ist und gibt klare Anweisung wenn nicht
- Package-Datei idempotent — keine Duplikate möglich

---

## [1.3.0] — 2025-03-01

### Sicherheit
- `--dangerously-skip-permissions` entfernt — `settings.json` gilt wieder vollständig
- `settings.json` von Blacklist auf Allowlist umgestellt (Default-deny für `Bash`)
- `Write` auf `/config/**` beschränkt — kein Schreiben in `/etc`, `/usr`, `/root/.ssh`
- `rm *` explizit verboten

### Neu
- **Auto-Update** — 1x täglich von GitHub, alle 4 Komponenten
- `installed_version` unter `/config/.lily-agent/installed_version`
- Telegram-Benachrichtigung bei Update: `🔄 hostname — Update 1.2.0 → 1.3.0`
- `GITHUB_REPO` Variable im Wrapper

### Telegram
- Start-Nachricht auf 1 Zeile reduziert
- Idle-Nachricht auf 1 Zeile reduziert
- Ende-Nachricht: nur Status, Dauer, Dateinamen — kein Diff-Stat, kein Log-Pfad

### HomematicIP
- FRAMEWORK.md: `rx_mode: BURST` vs. `WAKEUP` dokumentiert
- FRAMEWORK.md: MASTER-Paramset Flash-Warnung ergänzt

---

## [1.2.0] — 2025-02-15

### Neu
- `cm backup` Subcommand — Pre-Session Backup mit Telegram
- inotify `--exclude` für `.git`, `logs/`, `backups/`, `.storage`, DB, Logfile
- Git Silent Mode — kein leerer Commit bei reinen Lese-Sessions
- FRAMEWORK.md Senior Standards (+98 Zeilen): Anti-Patterns, Entscheidungs-Kontext, Bekannte Eigenheiten
- `system-info.md` Self-Learning Architektur mit `- [ ]` Checkboxen
- CCU3-Scanner `ccu-scan.py`

### Optimierung
- CLAUDE.md: 251 → 133 Zeilen (Backup-Block in Wrapper ausgelagert)
- Gesamt-Tokenreduktion beim Start: ~20%

---

## [1.1.0] — 2025-02-01

### Neu
- Idle-Watchdog (45 Min, stoppt Claude Code Addon)
- Pre-Flight Check: Disk + RAM vor Session-Start
- Error-Eskalation mit Restore-Snippet in CLAUDE.md
- Persistenz unter `/config/.lily-agent/`
- Reinstall-Script für HA-Neustart via Automation

---

## [1.0.0] — 2025-01-15

### Initial Release
- Wrapper mit Telegram Start/Ende
- Session-Log unter `/config/logs/lily-agent/`
- inotifywait Dateiüberwachung
- Git-Commit am Session-Ende
- CLAUDE.md mit Namenskonvention, Config-Check, Entscheidungsmatrix
- SMARTHOMELILY_FRAMEWORK.md
- settings.json mit Blacklist
- Install-Script (One-Shot)
