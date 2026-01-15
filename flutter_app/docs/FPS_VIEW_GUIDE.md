# 🎯 SISTEMA DE VISTA EN PRIMERA PERSONA (FPS VIEW)

## 📋 Descripción General

El sistema FPS View proporciona una interfaz de primera persona **ÚNICA** para cada tipo de torre, permitiendo a los jugadores experimentar el combate desde la perspectiva de sus defensas. El sistema incluye un **MODO BOOST especial** que se activa automáticamente cuando hay un boss en el campo de batalla.

---

## 🎮 Características Principales

### Vista en Primera Persona

Cada torre tiene una interfaz FPS completamente única que refleja su personalidad y estilo de combate:

1. **Pulse Archer** - Vista de Arco Energético
2. **Circuit Cannon** - Vista de Artillería Pesada
3. **Phase Mage** - Vista de Bastón Arcano
4. **Glimmer Field** - Vista de Array Prismático

### Modo BOOST

Cuando un **boss** está activo en el campo:
- ✨ Fondo animado con rejilla ciber
- ⚡ Partículas de energía ascendentes
- 🔴 Indicador "BOOST MODE" pulsante
- 🌟 Efectos visuales mejorados en el arma
- 💥 Flash de recoil más intenso

---

## 🎨 INTERFAZ ÚNICA POR TORRE

### 1. 🎯 PULSE ARCHER - "ENERGY BOW"

**Apariencia**:
- Arco energético curvado color cyan
- Cuerda de energía pulsante
- Flecha cargada cuando está lista para disparar
- Brillo blanco en la punta de la flecha

**BOOST Mode**:
- Alas energéticas múltiples detrás del arco
- Aumenta visualmente el tamaño del arco
- Efecto de estela de energía

**HUD**:
- Color primario: Cyan (#00FFFF)
- Color secundario: Azul (#0088FF)
- Nombre: "PULSE ARCHER"
- Arma: "ENERGY BOW"

**Estilo de Juego**:
- Tiros rápidos y precisos
- Recarga visible con flecha materializándose
- Ideal para sniper de alta velocidad

---

### 2. 💥 CIRCUIT CANNON - "PLASMA ARTILLERY"

**Apariencia**:
- Cañón pesado rectangular
- Segmentos de circuito visible
- Indicador de carga que se llena al recargar
- Destello de boca cuando está listo

**BOOST Mode**:
- Bobinas de energía orbitando el cañón
- 6 anillos rotatorios de energía
- Efecto eléctrico intensificado

**HUD**:
- Color primario: Magenta (#FF00FF)
- Color secundario: Rosa (#FF0088)
- Nombre: "CIRCUIT CANNON"
- Arma: "PLASMA ARTILLERY"

**Estilo de Juego**:
- Daño masivo por disparo
- Recarga lenta pero impactante
- Perfecto para eliminar objetivos duros

---

### 3. 🔮 PHASE MAGE - "ARCANE STAFF"

**Apariencia**:
- Bastón místico con cristal flotante
- Cristal hexagonal que levita
- 4 partículas orbitando el cristal
- Animación de respiración en el cristal

**BOOST Mode**:
- Fisuras de fase emanando del cristal
- 8 rayos de energía conectados
- Efecto de distorsión dimensional

**HUD**:
- Color primario: Púrpura (#9C27B0)
- Color secundario: Violeta (#AA00FF)
- Nombre: "PHASE MAGE"
- Arma: "ARCANE STAFF"

**Estilo de Juego**:
- Magia arcana y control
- Revela enemigos phantom
- Aplica slow a los objetivos

---

### 4. ✨ GLIMMER FIELD - "PRISMATIC ARRAY"

**Apariencia**:
- 5 emisores prismáticos
- Cada emisor con efecto arco iris
- Animación de onda sinusoidal
- Rayos de energía cuando está cargado

**BOOST Mode**:
- Explosión prismática de 3 anillos
- 36 partículas de colores diferentes
- Efecto caleidoscopio completo

**HUD**:
- Color primario: Amarillo (#FFEB3B)
- Color secundario: Naranja (#FFAA00)
- Nombre: "GLIMMER FIELD"
- Arma: "PRISMATIC ARRAY"

**Estilo de Juego**:
- Disparos rápidos múltiples
- Daño bajo pero alta frecuencia
- Aplica slow con brillo

---

## 🎯 ELEMENTOS DEL HUD

### Top-Left: Información de Torre
```
PULSE ARCHER          ← Nombre
ENERGY BOW            ← Tipo de arma
```

### Top-Right: Estadísticas
```
DMG: 15               ← Daño actual
RNG: 160              ← Rango actual
ROF: 2.0/s            ← Tasa de disparo
```

### Bottom-Left: Indicador de Recarga
- Barra horizontal de 200px
- Verde cuando está READY
- Color de torre cuando recargando
- Texto "READY" o "RELOADING"

### Bottom-Right: Indicador BOOST (solo cuando hay boss)
```
>>> BOOST MODE <<<
```
- Texto pulsante grande
- Corchetes animados a los lados
- Brillo intenso del color de la torre

---

## 🎯 SISTEMA DE MIRA (CROSSHAIR)

### Mira Base
- Anillo rotatorio con 4 segmentos
- Centro con punto pequeño
- Radio: 30-35px (pulsante)
- Rotación continua a 0.5 rad/s

### Estados de Mira

#### Sin Objetivo
- Color: Color primario de la torre
- Opacidad: 80%
- Rotación normal

#### Target Lock (Objetivo Adquirido)
- Color: Cambia a ROJO
- Anillo adicional que se contrae
- Brackets en la posición del objetivo
- Texto "TARGET LOCKED" arriba

#### BOOST Mode
- Brillo intensificado
- Partículas adicionales en la mira
- Efecto de distorsión sutil

---

## ⚡ EFECTOS VISUALES

### Recoil (Retroceso)
Cuando la torre dispara:
- Arma se mueve 20px hacia abajo
- Decaimiento suave (100px/s)
- Flash blanco de pantalla completa (30% opacidad)
- Duración: ~0.2 segundos

### Partículas BOOST
Cuando BOOST mode está activo:
- 30 partículas por segundo
- Suben desde abajo
- Color del arma primario
- Gravedad inversa
- Vida: 2 segundos
- Máximo: 50 partículas simultáneas

### Background BOOST
- Rejilla animada moviéndose
- Espaciado: 50px
- Viñeta radial en los bordes
- Opacidad basada en intensidad de boost

---

## 🔧 IMPLEMENTACIÓN TÉCNICA

### Archivos Clave

**Principal**:
- `lib/src/game/fps/fps_view_component.dart` (900+ líneas)

**Soporte**:
- `lib/src/game/entities/tower.dart` (propiedades FPS añadidas)
- `lib/src/game/bored_games_game.dart` (gameTime)

### Propiedades de Torre para FPS

```dart
// En Tower class
double get currentDamage => damage;
double get currentFireRate => fireRate;
double get currentRange => range;
Enemy? get currentTarget => _currentTarget;
double get lastFireTime => _lastFireTime;
```

### Detección de BOOST Mode

```dart
// Automático basado en boss activo
final boss = gameRef.enemyManager.currentBoss;
_isBoostMode = boss != null && boss.isAlive;
```

### Activación de Recoil

```dart
// Llamar cuando la torre dispara
fpsViewComponent.triggerRecoil();
```

---

## 🎮 CÓMO USAR (Para Desarrolladores)

### Paso 1: Crear FPS View Component

```dart
final fpsView = FpsViewComponent(tower: myTower);
add(fpsView);
```

### Paso 2: Actualizar en Cada Frame

```dart
// Se actualiza automáticamente
// - Revisa estado de boss
// - Actualiza progreso de recarga
// - Anima elementos
```

### Paso 3: Trigger Recoil al Disparar

```dart
// En el callback de disparo de la torre
tower.onFire = (tower, target, targetPos) {
  fpsView.triggerRecoil();
  // ... resto del código de disparo
};
```

---

## 🎨 PERSONALIZACIÓN

### Cambiar Colores de Torre

Editar en `fps_view_component.dart` método `_initializeForTowerType()`:

```dart
case TowerType.pulseArcher:
  _primaryColor = const Color(0xFF00FFFF);    // Color principal
  _secondaryColor = const Color(0xFF0088FF);  // Color secundario
  _towerName = 'PULSE ARCHER';
  _weaponType = 'ENERGY BOW';
  break;
```

### Ajustar Sensibilidad de Boost

```dart
// Cambiar velocidad de transición
_boostIntensity += (targetBoost - _boostIntensity) * dt * 3;
                                                         ↑ velocidad
```

### Modificar Tasa de Partículas

```dart
// En _spawnBoostParticles()
if (math.Random().nextDouble() < dt * 30 * _boostIntensity) {
                                      ↑ partículas/segundo
```

---

## 📊 ESPECIFICACIONES TÉCNICAS

### Performance

- **Target FPS**: 60 FPS
- **Partículas máximas**: 50 simultáneas
- **Updates por frame**: ~10-15 elementos
- **Impacto de render**: Bajo (uso eficiente de Canvas)

### Memoria

- **Componente base**: ~50KB
- **Con partículas**: ~100KB
- **Total con assets**: ~150KB

### Compatibilidad

- ✅ Desktop (Windows, macOS, Linux)
- ✅ Web (CanvasKit)
- ✅ Mobile (Android, iOS)
- ⚠️ Reduce automáticamente efectos en dispositivos de baja potencia

---

## 🚀 MEJORAS FUTURAS

### Potenciales Expansiones

1. **Modo VR/AR**: Perspectiva 360°
2. **Controles Manuales**: Permitir al jugador disparar manualmente
3. **Mini-mapa**: Radar táctico en esquina
4. **Combo System**: Multiplicador por disparos consecutivos
5. **Achievements**: Por tiempo en FPS mode
6. **Grabación**: Replay del gameplay FPS
7. **Shake de Cámara**: Más intenso durante boss battles
8. **Depth of Field**: Desenfocar fondo/foreground
9. **Lens Flares**: Cuando el boss usa habilidades
10. **Kill Feed**: Notificaciones de eliminaciones

---

## ⚙️ CONFIGURACIÓN AVANZADA

### Activar/Desactivar FPS View

```dart
// Mostrar
if (!fpsViewActive) {
  final fpsView = FpsViewComponent(tower: selectedTower);
  add(fpsView);
  fpsViewActive = true;
}

// Ocultar
if (fpsViewActive) {
  fpsView?.removeFromParent();
  fpsViewActive = false;
}
```

### Ajuste de Intensidad Visual

```dart
// En render methods
final intensity = _boostIntensity; // 0.0 - 1.0

// Usar para modular efectos
final particleCount = (30 * intensity).toInt();
final glowOpacity = 0.4 * intensity;
final effectScale = 1.0 + (0.5 * intensity);
```

---

## 🐛 TROUBLESHOOTING

### Problema: FPS View no aparece
**Solución**: Verificar que la torre tenga `gameTime` actualizado

### Problema: Recoil no funciona
**Solución**: Asegurar que `triggerRecoil()` se llame en `onFire`

### Problema: BOOST mode no se activa
**Solución**: Verificar que `gameRef.enemyManager.currentBoss` no sea null

### Problema: Performance bajo
**Solución**: Reducir `_maxBoostParticles` de 50 a 30

---

## 📝 NOTAS DE DISEÑO

### Filosofía

El sistema FPS está diseñado para:
1. **Inmersión**: Sentirse parte de la batalla
2. **Feedback Visual**: Saber exactamente qué está pasando
3. **Distinción**: Cada torre se siente diferente
4. **Intensidad**: BOOST mode añade dramatismo

### Decisiones de Diseño

- **Por qué cada torre es diferente?**: Refleja su rol táctico
- **Por qué BOOST automático?**: No interrumpe el gameplay
- **Por qué no control manual?**: Mantiene el género Tower Defense
- **Por qué HUD minimalista?**: No obstruye la vista

---

¡El sistema FPS View añade una capa completamente nueva de inmersión al juego! 🎮🔫
