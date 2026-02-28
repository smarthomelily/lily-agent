# HA Managed Systems Agent — smarthomelily

## Start-Routine

1. Lesen: `/config/system-info.md` + `/config/SMARTHOMELILY_FRAMEWORK.md`
2. Fragen: „Backup vor dem Start? (ja/nein)" — bei Ja: `lia backup` ausführen und warten

Nicht fragen bei: nur lesende Aktionen, Nutzer sagt „kein Backup".

---

## Beim Arbeiten
Bei neuen Hardware-Erkenntnissen (Latenzen, Totzeiten, Fluktuationen):  Abschnitt **Hardware-Eigenheiten** sofort aktualisieren. Nach erster Implementierung eines neuen Patterns: Referenz-Implementierungen Tabelle im FRAMEWORK.md ergänzen.

## Regeln

| | |
|---|---|
| Sprache | Deutsch; Fachbegriffe + Code-Kommentare Englisch |
| Stil | Kein Fülltext, keine Wiederholungen, keine Zusammenfassungen |
| Unklarheiten | Nachfragen — niemals raten |

---

## Namenskonvention

**Entity-IDs:** `XX_Raum_YY_ZZ_VV_Bezeichnung`

| Pos | Inhalt | Werte |
|---|---|---|
| `XX` | Raumkürzel | `01` Flur · `02` Wohnzimmer · `04` Kueche · `06` Schlafzimmer · `07` Buero |
| `Raum` | Raumname | `Flur`, `Wohnzimmer`, `Kueche` … |
| `YY` | Gerätetyp | `LI` Licht · `HZ` Heizung · `SE` Sensor · `SW` Schalter · `ME` Media |
| `ZZ` | Technologie | `HM` HomematicIP · `ZB` Zigbee · `ES` ESPHome · `MT` Matter |
| `VV` | Variante | `01`, `02` … |

```
light.01_Flur_LI_HM_01_Decke          climate.06_Schlafzimmer_HZ_HM_01_Thermostat
binary_sensor.02_Wohnzimmer_SE_ZB_01_Bewegung    sensor.07_Buero_SE_ES_01_Temperatur
```

**Automations-IDs:** `XX_Raum_Funktion_Beschreibung` — Dateien: `XX_raumname.yaml`

⚠️ Kundensysteme: Bestehende Namen übernehmen, nicht umbenennen.

---

## Autonomes Arbeiten

**Direkt handeln, nicht fragen.** Ausnahmen: 1 Satz ankündigen, dann sofort ausführen.

| Ankündigen bei | Text |
|---|---|
| Datei löschen | „Lösche `<datei>` — Backup unter `/config/backups/`." |
| HA Core-Neustart | „Starte HA Core neu." |
| Integration entfernen | „Entferne `<n>` inkl. aller Entities." |

Backup vor destruktiven Aktionen: automatisch unter `/config/backups/pre-change_*`

---

## Config-Check (nach jeder Änderung)

```bash
R=$(curl -s -X POST -H "Authorization: Bearer ${SUPERVISOR_TOKEN}" http://supervisor/core/check)
echo "$R" | grep -q '"result":"ok"' && echo "✅" || { echo "❌ $R"; # → Telegram + Restore + Retry
}
```

---

## Fehler-Eskalation

```bash
BAK=$(ls -t /config/backups/pre-change_*_<f> 2>/dev/null | head -1)
[[ -n "$BAK" ]] && cp "$BAK" /config/<f>
source /etc/lily-notify.conf 2>/dev/null
curl -s -X POST "https://api.telegram.org/bot${TELEGRAM_BOT_TOKEN}/sendMessage" \
  -d chat_id="${TELEGRAM_CHAT_ID}" -d parse_mode="HTML" \
  -d text="🚨 <b>Fehler+Restore</b> | 🏠 <code>$(hostname)</code> | ♻️ <code>$(basename $BAK)</code>" > /dev/null 2>&1
```

---

## Git (Sessionende)

```bash
cd /config
[[ ! -d .git ]] && git init && git config user.email "claude@smarthomelily.local" && \
  git config user.name "Claude Code" && \
  printf ".storage/\nlogs/\nbackups/\nhome-assistant.log\nhome-assistant_v2.db*\n.cloud/\ndeps/\n.lily-agent/\nsystem-info.md\n" > .gitignore
CHANGED=$(git diff --name-only; git ls-files --others --exclude-standard)
[[ -n "$CHANGED" ]] && git add -A && \
  git commit -m "Session $(date '+%Y-%m-%d %H:%M') — $(echo "$CHANGED" | wc -l) Datei(en)
$(echo "$CHANGED" | sed 's/^/- /')"
```

---

## Entscheidungsmatrix

| Anwendungsfall | Ansatz |
|---|---|
| Wenn-Dann | YAML Automation |
| Wiederverwendbar | Blueprint |
| Komplex / API / Schleifen | AppDaemon |
| Einmalig | Script |
| Dashboard | Custom Card / Panel / Strategy |
| FSM (Hardware-Totzeiten, Override-Logik) | AppDaemon + input_select |

→ Tech-Stack, MD3, UI-Patterns: siehe `/config/SMARTHOMELILY_FRAMEWORK.md`

---

## Diagnose-Snippets

```bash
grep -i "error\|critical" /config/home-assistant.log | tail -30          # Logs
curl -s -X POST -H "Authorization: Bearer ${SUPERVISOR_TOKEN}" http://supervisor/core/check  # Validate
for d in /config/custom_components/*/; do                                # Components
  echo "$(basename $d): $(python3 -c "import json; print(json.load(open('${d}manifest.json')).get('version','?'))" 2>/dev/null)"
done
```

---

## Setup-Log

```bash
LOG="/config/logs/lily-agent/setup_$(date '+%Y-%m-%d_%H-%M-%S')_$(hostname).log"
mkdir -p /config/logs/lily-agent && echo "$(date) | $(hostname)" >> "$LOG"
# Jeden Befehl: cmd 2>&1 | tee -a "$LOG"
```
