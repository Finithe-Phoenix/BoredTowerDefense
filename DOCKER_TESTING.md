# Docker Testing Guide

Esta guía explica cómo ejecutar las pruebas automáticamente con Docker Compose.

## 🧪 Ejecución con Pruebas (Por Defecto)

Cuando ejecutas el comando estándar de Docker Compose, **las pruebas se ejecutan automáticamente** antes de iniciar la aplicación:

```bash
docker-compose up --build
```

### ¿Qué sucede?

1. ✅ Se construye la imagen Docker
2. ✅ Se instalan las dependencias (`flutter pub get`)
3. ✅ **Se ejecutan todas las pruebas** (`flutter test`)
4. ✅ Si las pruebas pasan → La aplicación se inicia
5. ❌ Si las pruebas fallan → La aplicación NO se inicia

### Salida Esperada:

```
==========================================
  🧪 Ejecutando pruebas unitarias...
==========================================

00:01 +1: Boss creates mini-boss with correct stats
00:02 +2: Boss creates world boss with correct stats
...
00:45 +600: All tests passed!

==========================================
  ✅ Todas las pruebas pasaron exitosamente!
==========================================

🚀 Iniciando aplicación...
```

---

## 🚀 Ejecución sin Pruebas (Desarrollo Rápido)

Si quieres desarrollar rápidamente **sin ejecutar las pruebas**, usa el servicio alternativo:

```bash
docker-compose up bored-games-dev --build
```

### ¿Qué sucede?

1. ✅ Se construye la imagen Docker
2. ✅ Se instalan las dependencias
3. ⚠️ **Se saltan las pruebas**
4. ✅ La aplicación se inicia directamente

### Salida Esperada:

```
==========================================
  ⚠️  Modo desarrollo - sin pruebas
==========================================

🚀 Iniciando aplicación directamente...
```

---

## 📊 Comparación de Comandos

| Comando | Ejecuta Pruebas | Bloquea si Fallan | Uso Recomendado |
|---------|----------------|-------------------|-----------------|
| `docker-compose up` | ✅ Sí | ✅ Sí | Producción, CI/CD, Deploys |
| `docker-compose up bored-games-dev` | ❌ No | N/A | Desarrollo local rápido |

---

## 🔧 Scripts Disponibles

El proyecto incluye dos scripts de entrypoint:

### 1. `entrypoint.sh` (Por defecto)
- Ejecuta `flutter test`
- Si las pruebas pasan → Inicia la app
- Si las pruebas fallan → Termina con código de error

### 2. `entrypoint-no-tests.sh` (Desarrollo)
- Salta las pruebas completamente
- Inicia la app inmediatamente

---

## 📝 Logs y Debugging

### Ver logs en tiempo real:
```bash
docker-compose up
```

### Ver logs de un contenedor específico:
```bash
docker logs bored_games_flutter
```

### Ver logs sin seguir:
```bash
docker-compose logs
```

---

## 🐛 Solución de Problemas

### Las pruebas fallan al iniciar:

1. **Verifica el código de las pruebas**:
   ```bash
   cd flutter_app
   flutter test
   ```

2. **Revisa los logs del contenedor**:
   ```bash
   docker logs bored_games_flutter
   ```

3. **Usa el modo desarrollo para saltarte las pruebas temporalmente**:
   ```bash
   docker-compose up bored-games-dev
   ```

### Error de permisos con entrypoint.sh:

Si ves un error como `permission denied: ./entrypoint.sh`:

```bash
# En Windows con WSL o Git Bash:
cd flutter_app
chmod +x entrypoint.sh
chmod +x entrypoint-no-tests.sh

# Reconstruir la imagen:
docker-compose build
```

### El contenedor se detiene después de las pruebas:

Esto es normal si las pruebas **fallan**. El contenedor termina con un código de error para indicar que algo salió mal.

Para ver qué prueba falló:
```bash
docker-compose up | grep "FAIL"
```

---

## 🔄 Flujo de Trabajo Recomendado

### Durante Desarrollo:
```bash
# Modo rápido sin pruebas
docker-compose up bored-games-dev
```

### Antes de Commit:
```bash
# Ejecutar pruebas localmente
cd flutter_app
flutter test

# O ejecutar con Docker
docker-compose up --build
```

### En CI/CD:
```bash
# Siempre con pruebas
docker-compose up --build
```

### Para Deploy:
```bash
# Construir y verificar
docker-compose up --build

# Si todo pasa, deployar
```

---

## 📋 Cobertura de Pruebas

Las pruebas incluidas cubren:

- ✅ **600+ casos de prueba**
- ✅ Boss system (11 tipos de jefes)
- ✅ FPS view component (4 tipos de torres)
- ✅ Enemy manager integration
- ✅ Boss health bar
- ✅ Pruebas de integración end-to-end

Para ver un resumen completo:
```bash
cat flutter_app/TEST_SUMMARY.md
```

---

## 🎯 Comandos Útiles

```bash
# Iniciar con pruebas (recomendado)
docker-compose up --build

# Iniciar sin pruebas (desarrollo)
docker-compose up bored-games-dev --build

# Detener todos los contenedores
docker-compose down

# Ver logs
docker-compose logs -f

# Ejecutar pruebas manualmente dentro del contenedor
docker exec bored_games_flutter flutter test

# Reconstruir imagen completa
docker-compose build --no-cache

# Limpiar todo y empezar de cero
docker-compose down -v
docker-compose build --no-cache
docker-compose up
```

---

## ✨ Ventajas de Este Enfoque

1. **Calidad Garantizada**: No se puede iniciar una app con pruebas rotas
2. **CI/CD Ready**: Perfecto para pipelines de integración continua
3. **Flexible**: Modo desarrollo para iteración rápida
4. **Feedback Inmediato**: Sabes al instante si algo se rompió
5. **Documentado**: Logs claros sobre qué está pasando

---

## 📚 Recursos Adicionales

- [TEST_SUMMARY.md](flutter_app/TEST_SUMMARY.md) - Documentación completa de pruebas
- [BOSS_GUIDE.md](flutter_app/docs/BOSS_GUIDE.md) - Guía de sistema de jefes
- [FPS_VIEW_GUIDE.md](flutter_app/docs/FPS_VIEW_GUIDE.md) - Guía de vista FPS

---

*Última actualización: 2026-01-13*
