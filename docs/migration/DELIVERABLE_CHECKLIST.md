# Neon Defense (Unreal) — Hoja de ruta a "Producto Entregable"

**Estado a 2026-06-07.** Este documento separa lo que ESTÁ hecho (prototipo jugable en editor) de lo que falta
para un **producto entregable** (un build que un jugador descarga y juega), con estado honesto de cada ítem.

> Resumen honesto: hoy hay un **prototipo jugable y muy completo dentro del Editor de Unreal**. Para ser un
> "producto entregable de verdad" faltan: un build empaquetado verificado, audio, un envoltorio de menú/flujo,
> y una verificación de juego real de extremo a extremo. Este doc rastrea esos pasos.

---

## A. Núcleo jugable — HECHO ✅ (validado en PIE)
- [x] 9 torres con habilidades distintas + mejoras 1→4
- [x] ~10 enemigos + mini-boss + 2 world bosses (phantom, minions, fases)
- [x] Economía de oro (ganar/gastar/reembolso)
- [x] Oleadas multi-fase + campaña de 100 niveles (auto-avance + por botón)
- [x] Guardado/persistencia de progreso (`USaveGame` slot `BTDCampaign`)
- [x] Curva de dificultad (HP escala por nivel; nivel 1 = ×1.0)
- [x] Interacción de jugador: paleta (1-9), clic colocar/seleccionar, U mejorar, X vender, panel de torre
- [x] Menús de fin de partida (banner + Next Level / Restart), indicador de rango
- [x] Overhaul visual: suelo-rejilla Tron, post-procesado cinemático, materiales Fresnel, mallas con silueta,
      núcleos flotantes, barras de vida, HUD neón con barra de boss

## B. Empaquetado / build entregable — EN PROGRESO 🔄
- [~] **Empaquetar build standalone Win64** — *INTENTADO 2026-06-07: el cook arrancó y progresó, pero se
      **detuvo por falta de RAM** en esta máquina (sólo ~1.3 GB libres; el cook avisaba "Out of memory").
      No es un error del proyecto — sólo memoria. **Re-lanzar desde cowork** (máquina con más RAM, editor
      cerrado) con:*
  ```
  "C:\Program Files\Epic Games\UE_5.7\Engine\Build\BatchFiles\RunUAT.bat" BuildCookRun ^
    -project="...\BoredTowerDefense.uproject" -noP4 -platform=Win64 -clientconfig=Development ^
    -cook -build -stage -pak -archive -archivedirectory="...\Packaged" -nocompileeditor -utf8output
  ```
  *(si vuelve a faltar memoria: cerrar OneDrive/apps, o cookear 1 mapa, o usar `-clientconfig=Shipping`.)*
- [ ] Verificar que el `.exe` empaquetado **arranca y corre** fuera del editor
- [ ] Verificar que el guardado funciona en el build empaquetado (ruta de `Saved/`)
- [ ] Config de empaquetado: mapa por defecto = `L_NeonSkeleton` ✅ (ya configurado)
- [ ] Decidir config: **Development** (con logs/debug) vs **Shipping** (final, optimizado, sin debug)
- [ ] Icono + nombre de la app + splash (branding mínimo)

## C. Audio — NO HECHO ❌ (bloqueado por assets)
- [ ] Conseguir/añadir **assets de sonido** al proyecto (SFX disparo/impacto/muerte/UI, música) — *necesita el usuario*
- [ ] Cablear los hooks de sonido (campos `USoundBase` en data assets + `PlaySound`/MetaSounds)
- [ ] Mezcla básica (volumen maestro, SFX vs música) + opción de mute

## D. Envoltorio de juego / UX de producto — NO HECHO ❌
- [ ] **Pantalla de inicio / Main Menu** (Play / Continuar / Salir) que enlace el flujo
- [ ] Menú de pausa (Esc → Reanudar/Reiniciar/Salir)
- [ ] Pantalla de opciones (volumen, calidad gráfica)
- [ ] Flujo: Menú → Juego → fin → Menú (hoy arranca directo en el showcase)

## E. Verificación de juego real — NO HECHO ❌
- [ ] **Playthrough humano de extremo a extremo** con ratón/teclado (no solo validación automatizada por Python)
- [ ] Pasar varios niveles seguidos comprobando que no hay bugs de flujo (avance, guardado, derrota, reinicio)
- [ ] Comprobar legibilidad/jugabilidad de la cámara y la colocación con ratón real
- [ ] Pase de balance (¿la curva de dificultad se siente bien? ¿la economía cuadra?)

## F. Contenido y pulido (para calidad de producto) — PARCIAL 🔄
- [ ] Oleadas/dificultad **por-nivel** reales (hoy se reusa un set de oleadas para los 100 niveles)
- [ ] Mallas custom reales (hoy primitivas: conos/esferas/cilindros)
- [ ] Más VFX (Niagara), pulido de cámara, backdrop/skybox
- [ ] Modo FPS pseudo-3D (feature grande del juego original Flutter, aún sin migrar)

---

## Veredicto por nivel de "entregable"
| Nivel | ¿Listo? | Qué falta |
|---|---|---|
| **Prototipo jugable (en editor)** | ✅ SÍ | nada — está completo y validado |
| **Demo empaquetada (build que arranca)** | 🔄 casi | terminar §B (empaquetar + verificar arranque) |
| **Producto entregable (jugable, con audio + menús)** | ❌ no aún | §B + §C (audio) + §D (menús) + §E (playthrough) |
| **Producto pulido / completo** | ❌ no | + §F (contenido por-nivel, arte custom, FPS) |

## Próximos pasos inmediatos (lo que estoy haciendo)
1. ⏳ Empaquetar el build standalone y verificar que arranca (§B).
2. ⏭️ Añadir un **Main Menu + menú de pausa** (§D) — no necesita assets externos.
3. ⏭️ Cablear la **infraestructura de audio** (§C) lista para cuando aporte assets de sonido.
4. 📋 Documentar todo a medida (este doc + `HANDOFF.md` + `STATUS_REPORT.md`).
