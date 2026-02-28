# SMARTHOMELILY_FRAMEWORK.md

## Logic-Entscheidung

| Situation | Ansatz |
|---|---|
| Wenn-Dann ohne Overrides | YAML Automation |
| Hardware-Totzeiten (PIR), manuelle Overrides, kritische Ketten | FSM via AppDaemon + input_select |

## FSM-Standards

- 1 Automation, `choose:`-Blöcke, `mode: queued`
- Zustand in `input_select` (überlebt Neustart, Dashboard-sichtbar, manuell überschreibbar)

| Zustand | Bedeutung |
|---|---|
| `OFF` | Ruhezustand |
| `ACTIVE` | Trigger aktiv |
| `COOLDOWN` | Gnadenfrist vor Ausschalten |
| `MANUAL_ON` | Manuell ein, Automation pausiert |
| `MANUAL_OFF` | Manuell gesperrt |

## Frontend

- **Lit 3.x** + Web Components — kein Build-Step, ES Modules in `/config/www/`
- **MD3 Tokens** — kein hardcoding, Light/Dark via `_applyColorMode()`
- **Branding:** `#10b981` (smarthomelily Grün)
- Vor Neuentwicklung: [design.home-assistant.io](https://design.home-assistant.io) — `ha-*` Element?

## GitHub / HACS

- Repos: `lovelace-<n>` (Cards) · `ha-<n>` (Integrationen) · `smarthomelily` Org
- Lizenz: GNU GPL v3 · README: zweisprachig DE/EN
- Release: `gh release create vX.Y.Z dist/<n>.js` — nur Releases werden von HACS erkannt
- Semantic Versioning: Breaking→MAJOR · Feature→MINOR · Fix→PATCH

## Pre-Release Checklist

`hacs.json` · `README.md` mit Screenshot · `dist/<n>.js` · `.github/workflows/validate.yml` · `LICENSE`

## Agent-Checks vor jeder Änderung

1. FSM wirklich nötig?
2. MD3-Tokens + `#10b981`?
3. Portabel, keine externen JS-Dependencies?

---

## Senior Standards

### Entscheidungs-Kontext

**delay vs. wait_for_trigger**
`delay` bricht bei HA-Neustart ab und hinterlässt inkonsistente Zustände.
`wait_for_trigger` mit `timeout` ist restart-safe — immer bevorzugen.
```yaml
# ❌ Nicht so:
- delay: "00:05:00"
# ✅ So:
- wait_for_trigger:
    - trigger: state
      entity_id: binary_sensor.01_Flur_SE_ZB_01_Bewegung
      to: "off"
  timeout: "00:05:00"
  continue_on_timeout: true
```

**mode: restart vs. queued**
`restart`: Trigger während Ausführung → neustart. Gut für einfache Licht-Automations.
`queued`: Trigger wird eingereiht. Pflicht bei FSMs — verhindert verlorene Events während Zustandswechsel.

**Trigger-Kontext: physical vs. automation**
Taster-Trigger und Automations-Trigger auf derselben Entität unterscheiden via `context`:
```yaml
condition: template
value_template: "{{ trigger.to_state.context.parent_id is none }}"  # nur physische Auslösung
```

---

### Anti-Patterns

| Anti-Pattern | Problem | Lösung |
|---|---|---|
| `delay` in `mode: restart` | Delay bricht ab, Licht bleibt an | `wait_for_trigger` mit timeout |
| `states()` ohne `default` | Fehler wenn Entity unavailable | `states() \| default('off')` |
| Hardcoded Entity-IDs in Templates | Bricht bei Umbenennung | Input-Variable oder Blueprint-Input |
| Mehrere Automations auf selber Entity ohne Koordination | Race Conditions | FSM oder `mode: single` mit `max_exceeded: silent` |
| `trigger: state` ohne `to:` | Feuert bei jedem Attribut-Update | Immer `to:` oder `attribute:` spezifizieren |
| `service_template` (deprecated) | Funktioniert nicht mehr | `action:` mit `target:` |

---

### Bekannte System-Eigenheiten

**HomematicIP (HM)**
- Aktorantwort verzögert ~300–800ms nach Befehl → kein sofortiger State-Check danach
- Bei Unterputzaktoren: Status-Polling alle 60s — nicht auf sofortige Rückmeldung verlassen
- Wired-Geräte stabiler als Funk — Funk-PIR können bei schwachem Signal `unavailable` fluktuieren
- `put_paramset` mit `rx_mode: BURST` (Default) weckt **alle** BidCos-RF Geräte gleichzeitig → Batterieverlust. Bei Konfigurationsänderungen `rx_mode: WAKEUP` verwenden (sendet beim nächsten regulären Wake-up, ~3 Min Verzögerung)
- MASTER-Paramset schreiben sparsam einsetzen — zu häufige Schreibzugriffe können Flash-Speicher des Geräts beschädigen (CCU-Warnung beachten)

**Zigbee (ZB)**
- IKEA-Sensoren: Bewegungs-Reset nach fest codierter Totzeit (Modell-abhängig: 30–180s)
- Beim Coordinator-Wechsel: Alle Geräte neu pairen — Entity-IDs bleiben bei korrektem Naming
- Occupancy-Sensor meldet `off` erst nach Totzeit → FSM `COOLDOWN` erst danach starten

**ESPHome (ES)**
- Bei OTA-Update kurz `unavailable` → Automations mit `for:` Verzögerung absichern
- Deep-Sleep-Sensoren: nur periodisch online — keine Echtzeit-Steuerung möglich

---

### Sicherheitszustände

Beim Sensorausfall (`unavailable`) darf Licht/Heizung nicht abrupt abschalten:
```yaml
condition: not
conditions:
  - condition: state
    entity_id: binary_sensor.01_Flur_SE_ZB_01_Bewegung
    state: "unavailable"
```
Oder in Templates: `is_state('binary_sensor.xyz', 'unavailable')` prüfen und Fallback definieren.

---

### Referenz-Implementierungen

Bewährte Patterns aus dem System — reproduzieren statt neu erfinden:

| Pattern | Beschreibung | Datei |
|---|---|---|
| Bewegungslicht mit FSM | PIR → ACTIVE → COOLDOWN → OFF, manueller Override | *(erste Implementierung hier eintragen)* |
| Heizung Nachtabsenkung | Zeitplan + Fenster-Kontakt-Override | *(erste Implementierung hier eintragen)* |

*Eintrag ergänzen nach jeder ersten Implementierung eines neuen Patterns.*

---

### Planungs-Direktive

Bei Aufgaben die Logik ändern (neue FSM, komplexe Templates, Multi-Room-Koordination):
1. Kurzen Plan skizzieren bevor Code geschrieben wird
2. Mindestens ein Edge-Case benennen (Sensor unavailable? HA-Neustart mittendrin? Gleichzeitige Trigger?)
3. Prüfen: Gibt es eine Referenz-Implementierung die reproduziert werden kann?
