# Lily Agent

**Managed agent runtime for Home Assistant** — von smarthomelily.

[![Version](https://img.shields.io/badge/version-1.7.2-green)](CHANGELOG.md)

---

## Was ist Lily Agent?

Eine vollständige Managed Agent Runtime für Home Assistant OS.  
Designed für professionellen Einsatz auf eigenen und betreuten Kundensystemen.

**Enthält:**
- `lily-agent` — Shell-Wrapper mit Auto-Update, Telegram, Logging, Idle-Watchdog
- `CLAUDE.md` — Agent-Prompt mit HA-spezifischen Regeln und Namenskonvention
- `SMARTHOMELILY_FRAMEWORK.md` — Senior Standards, Anti-Patterns, Hardware-Eigenheiten
- `settings.json` — Claude Code Permissions (Allowlist, Default-deny für destruktive Aktionen)
- `system-info.md` — Systemgedächtnis: Hardware, Integrationen, Eigenheiten

---

## Schnellinstall

```bash
# Im Claude Code Terminal (HA) — einmalig ausführen:
curl -fsSL https://raw.githubusercontent.com/smarthomelily/lily-agent/main/install.sh | bash
```

### Voraussetzungen
- Home Assistant OS
- Claude Code Addon installiert
- Telegram Bot Token + Chat ID

---

## Auto-Update

Der Wrapper prüft **einmal täglich** ob eine neue Version verfügbar ist.  
Bei Update: alle Komponenten werden automatisch ersetzt, Telegram-Benachrichtigung, Wrapper-Neustart.

```
🔄 mein-ha-system — Update 1.7.x → 1.7.2
```

Policy (`settings.json`) wird **nie** automatisch aktualisiert — nur explizit:
```bash
lia update --settings   # zeigt Quelle, fragt Bestätigung
```

Manuelles Update erzwingen:
```bash
rm /config/.lily-agent/last_update_check && lia
```

---

## Verwendung

```bash
lia                   # Lily Agent starten (Auto-Update + Logging + Watchdog)
lia backup            # Pre-Session Backup erstellen
lia update --settings # Security-Policy manuell aktualisieren
```

---

## Dateistruktur nach Installation

```
/usr/local/bin/lily-agent                # Binary
/config/CLAUDE.md                        # Agent-Prompt
/config/SMARTHOMELILY_FRAMEWORK.md       # Framework
/config/system-info.md                   # Systemgedächtnis (nicht in Git)
/root/.claude/settings.json              # Permissions (Policy)
/etc/lily-notify.conf                    # Telegram-Credentials (chmod 600)
/config/packages/lily_agent.yaml         # HA shell_command + Automation
/config/.lily-agent/                     # Persistenz (überlebt HAOS-Neustart)
  ├── lily-agent
  ├── CLAUDE.md
  ├── SMARTHOMELILY_FRAMEWORK.md
  ├── settings.json
  ├── lily-notify.conf
  ├── installed_version                  # "1.7.2"
  ├── last_update_check                  # Unix-Timestamp
  └── reinstall.sh                       # Via HA-Automation nach Neustart
/config/logs/lily-agent/                 # Session-Logs (90 Tage Retention)
```

---

## Telegram-Nachrichten

| Event | Format |
|---|---|
| Start | `🟢 hostname — Lily Agent gestartet \| 2025-03-01 14:32` |
| Ende (OK) | `✅ hostname — 12m 34s` + Dateiliste |
| Ende (Fehler) | `❌ hostname — 3m 12s` |
| Idle-Timeout | `⏸ hostname — Idle 10min — gestoppt` |
| Update | `🔄 hostname — Update 1.7.x → 1.7.2` |
| Backup | `💾 hostname — pre-session_... \| 420 MB` |

---

## Security

- Kein `--dangerously-skip-permissions`
- `settings.json`: Allowlist statt Blacklist — `Bash(rm *)` explizit verboten
- `Write` nur auf `/config/**`
- `curl` nur Supervisor-API, Telegram und Lily Agent Repo
- Telegram-Credentials unter `/etc/lily-notify.conf` (chmod 600, nie in Git)
- `.lily-agent/` und `system-info.md` in `.gitignore` — kein Credential- oder Systemdaten-Leak
- `settings.json` wird nie automatisch remote überschrieben

---

## Bekannte Einschränkungen

- `lily_agent.yaml` (HA-Package) wird nur beim Erstinstall angelegt — Änderungen kommen bei bestehenden Installationen nicht automatisch an. Manueller Fix: Datei unter `/config/packages/lily_agent.yaml` löschen und `install.sh` erneut ausführen.

---

## Versionierung

Semantic Versioning: `MAJOR.MINOR.PATCH` — siehe [CHANGELOG.md](CHANGELOG.md)

---

## Lizenz

GNU General Public License v3.0 — [smarthomelily](https://github.com/smarthomelily)
