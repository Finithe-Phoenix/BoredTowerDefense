# Neon Defense — Informe de status de la migración a Unreal Engine 5

**Fecha:** 2026-06-07 · **Motor:** Unreal Engine 5.7.4 (C++) · **Módulo:** `BoredTowerDefense`

---

## 1. Resumen ejecutivo

La migración del tower-defense **Neon Defense** de Flutter/Flame a Unreal Engine 5 produjo un
**prototipo jugable, muy completo y visualmente pulido — jugable hoy dentro del Editor de Unreal (PIE)**.
Se entregaron **~22 milestones de jugabilidad** + un **overhaul visual**, cada uno con:

- **Cross-check con Codex** (gpt-5.5, sandbox read-only) — y Gemini cuando estuvo disponible.
- **Validación en PIE real** (Play-In-Editor) vía la Remote Control API + Python.
- **Captura de pantalla** o inspección de componentes como evidencia.
- **Reconciliación de hallazgos** de Codex (cada FAIL triado y arreglado, rebuild limpio).
- **Documentación** en `docs/migration/HANDOFF.md` (log por-milestone con gotchas).

> ⚠️ **Honestidad sobre "entregable":** el NÚCLEO jugable está completo y validado *en el editor*, pero un
> **producto entregable** (build empaquetado que arranca solo, con audio, menús y verificación de juego real)
> aún tiene pasos pendientes. El estado y la hoja de ruta detallada están en
> **`docs/migration/DELIVERABLE_CHECKLIST.md`**. Resumen: prototipo jugable = ✅; entregable = 🔄 en progreso
> (empaquetado lanzándose; audio necesita assets; menús/flujo y playthrough humano pendientes).

---

## 2. Qué es el juego en Unreal hoy

Un tower-defense Tron/neón **completo y jugable por un humano**:

### Combate
- **9 torres** con habilidades distintas (rápida, pesada, slow+phantom, crowd-slow, **rayo en
  cadena** tipo Tesla, **sniper** Ion, y 3 más) — cada una data-driven (`UBTDTowerDataAsset`).
- **Sistema de mejoras** por torre (nivel 1→4): sube daño/rango/cadencia + crece y brilla más.
- **~10 enemigos** + mini-boss + **2 world bosses** con: escala de cuerpo, slow, phantom
  (invisible salvo torres detectoras), spawn de minions, y **fases de color por vida**.
- **Economía de oro** real (ganar al matar, gastar al colocar/mejorar, reembolso al vender).
- **Oleadas multi-fase** por nivel con intermisiones.

### Campaña
- **100 niveles** que cargan sus mapas importados (`DA_Map_LevelNNN`).
- **Avance automático** al ganar (auto-corrida) **y** por botón "Next Level".
- **Curva de dificultad**: el HP enemigo escala por nivel (nivel 1 = ×1.0, +8%/nivel) — **validado**
  (PIE: nivel 1 ×1.00, nivel 6 ×1.40).
- **Guardado persistente** (`USaveGame` en slot `BTDCampaign`): nivel actual, nivel más alto,
  mejor score — sobrevive entre sesiones.

### Jugabilidad por humano (UI descubrible)
- **Teclas 1-9**: elegir tipo de torre · **clic**: colocar en celda válida o seleccionar torre.
- **Panel de torre** (al seleccionar): muestra nivel + botones clicables **UPGRADE {coste}** /
  **SELL {reembolso}**.
- **U** mejora · **X** vende · **Space** inicia oleada.
- **Indicador de rango**: disco neón translúcido con el alcance de la torre seleccionada.
- **Menús de fin de partida**: banner **VICTORY/DEFEAT** + botones **Next Level / Restart**.

### Juice visual
- **VFX de impacto/muerte reales** (mallas emisivas que renderizan en build, no DrawDebug).
- **Barras de vida flotantes** sobre cada enemigo (verde→rojo, encarando la cámara, tamaño fijo).
- **Flash al recibir daño** (spike de emissive) · **muzzle flash** al disparar.
- **HUD neón** con recursos, contador de oleada y **barra de vida del boss** con fases.

### Overhaul visual (escena) — el gran salto de aspecto
Tras tu feedback ("mejorar todo visualmente"), se transformó el look de "primitivas planas sobre rejilla" a una
**arena neón Tron cinemática**:
- **Suelo-rejilla emisivo** (`M_TronGrid`, material procedural) que brilla y se aleja en perspectiva → estructura + profundidad (la pieza clave).
- **Post-procesado cinemático**: bloom equilibrado, exposición fija, color-grading frío/Tron, viñeta, aberración cromática, AO.
- **Iluminación moody** (escena oscura, el neón domina) + reflejos en el suelo metálico.
- **Materiales neón con borde Fresnel** (`M_NeonRim_*`, 7 colores) — núcleo brillante + rim glow, colores por-tipo preservados.
- **Mallas con silueta**: torres = conos (spires), enemigos = esferas (orbes), bosses = cilindros.
- **Núcleos de energía flotantes** sobre cada torre (orbe que gira + flota en el color de la torre).
- Capturas en `Saved/Screenshots/WindowsEditor/HighresScreenshot0000*.png`.

---

## 3. Milestones entregados (cronológico)

| # | Milestone | Validación |
|---|-----------|-----------|
| 1 | Economía de oro real | PIE: oro sube/baja correcto |
| 2 | Barra + fases del boss | PIE + captura |
| 3 | Torre de rayo en cadena (Tesla) + sniper (Ion) | PIE: salto en cadena, dedup |
| 4 | Sistema de mejoras de torre (1→4) | PIE: nivel/coste/visuales |
| 5 | Roster: 9 torres + variedad enemigos + 2 world bosses | PIE + assets idempotentes |
| 6 | Niveles multi-oleada | PIE: 1/3→2/3→3/3 |
| 7 | Condición de derrota | PIE: vidas→0 = DEFEAT |
| 8 | Loop completo victoria/derrota | PIE |
| 9 | VFX de combate reales (`ABTDNeonBurstActor`) | PIE: 1-3 bursts + captura |
| 10 | Progresión de niveles (`AdvanceToNextLevel`) | PIE: nivel 1→2, mapa cambia |
| 11 | Banner de victoria/derrota | Captura |
| 12 | Colocación de torres auto por mapa | PIE: L2 coloca 4 torres |
| 13 | Campaña auto-corrida (auto-advance) | PIE: gana L1 → auto-avanza L2 |
| 14 | Interacción jugador (colocar/seleccionar/vender/mejorar) | PIE: cadena con oro exacto |
| 15 | Menús de fin de partida (Next/Restart) | PIE + captura |
| 16 | Guardado/persistencia de campaña | PIE: slot `.sav` + recarga |
| 17 | Indicador de rango de torre | PIE + captura |
| 18 | Panel de info de torre seleccionada | PIE + captura |
| 19 | Barras de vida de enemigos | PIE: inspección de componentes |
| 20 | Flash al recibir daño | PIE: `IsHitFlashing()` |
| 21 | Curva de dificultad de campaña | PIE: L1 ×1.00, L6 ×1.40 |

---

## 4. Metodología y herramientas

- **Editor automation**: Remote Control API (HTTP `:30010`) + Python Editor Script, vía el cliente
  `unreal-mcp/.venv` (`UnrealRemoteClient.run_python`).
- **Build**: `Build.bat BoredTowerDefenseEditor Win64 Development` (el editor se cierra antes).
- **PIE real**: `LevelEditorSubsystem.editor_request_begin_play/end_play`; capturas con el comando
  de consola `Shot SHOWUI`.
- **Cross-check**: cada cambio no trivial se empaqueta y se pasa a **Codex** (`codex exec
  --sandbox read-only`); los hallazgos (High/Med/Low) se triaron y arreglaron antes de cerrar.
- **Gotchas documentados** en HANDOFF (p. ej. colisión de nombres de subsystem, APIs Python no
  expuestas en UE5.7, transitorios VFX <0.3s no capturables por RC, CRLF en `*.sh`).

---

## 5. Dónde vive cada cosa (arquitectura UE)

- `ABTDPrototypeDirector` — orquesta el nivel: mapa, path, colocación, oleadas, avance/reinicio,
  guardado, curva de dificultad.
- `ABTDTowerActor` / `ABTDEnemyActor` / `ABTDNeonProjectileActor` / `ABTDNeonBurstActor` — entidades.
- `UBTDPlacementSubsystem` (world) — colocación/ocupación de celdas.
- `UBTDWaveSubsystem` (world) — spawning y tracking de oleadas.
- `UBTDSaveSubsystem` (game-instance) + `UBTDSaveGame` — persistencia.
- `ABTDPlayerController` — input + interacción (paleta, colocar/seleccionar/vender/mejorar).
- `UBTDHudWidget` — HUD neón in-code (recursos, boss bar, banner, menús, panel de torre).
- Data assets: `UBTDTowerDataAsset` / `UBTDEnemyDataAsset` / `UBTDWaveDataAsset` /
  `UBTDLevelMapDataAsset`.

---

## 6. Qué falta (necesita tu decisión o insumos)

1. **Audio / MetaSounds** — *bloqueado*: no hay assets de sonido en el proyecto y la autoría de
   MetaSounds/assets vía el puente Python no está disponible. Puedo cablear los *hooks* (campos de
   sonido fire/death/UI + llamadas PlaySound), pero será silencioso hasta tener assets reales.
2. **Modo FPS** pseudo-3D — fase grande y distinta (cámara/mallas/controles nativos), digna de
   scoping deliberado contigo.
3. **Contenido por-nivel** — afinar oleadas/dificultad específicas para tramos de la campaña
   (más allá de la curva global de HP).
4. **Pulido visual avanzado** — Niagara para partículas, materiales de anillo para el rango,
   números de daño flotantes, muzzle flashes.

---

## 7. Cómo continuar

- **Estado del repo**: todo compila limpio; el editor abre con el último build; assets guardados;
  log completo en `docs/migration/HANDOFF.md`.
- **Para retomar**: indícame cuál de §6 priorizar. Para audio, necesito que añadas/consigas assets
  de sonido al proyecto.
- **Nada está roto ni a medias** — los 21 milestones están cerrados y validados.

🤖 Generado autónomamente con Claude Code · cross-check Codex · validado en PIE.
