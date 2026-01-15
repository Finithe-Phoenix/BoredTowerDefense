# 🧪 Testing Setup - Resumen de Configuración

## ✅ Cambios Realizados

Se ha configurado el proyecto para ejecutar pruebas automáticamente en Docker y CI/CD.

---

## 📁 Archivos Creados

### 1. Scripts de Entrypoint

**flutter_app/entrypoint.sh**
- Ejecuta `flutter test` antes de iniciar la app
- Si las pruebas fallan → App no se inicia
- Si las pruebas pasan → App se inicia normalmente

**flutter_app/entrypoint-no-tests.sh**
- Inicia la app directamente sin ejecutar pruebas
- Útil para desarrollo rápido

### 2. Documentación

**DOCKER_TESTING.md**
- Guía completa de cómo usar Docker con pruebas
- Comandos y ejemplos
- Solución de problemas

**TESTING_SETUP.md** (este archivo)
- Resumen rápido de la configuración

---

## 🔧 Archivos Modificados

### 1. Dockerfile
**Cambios:**
```dockerfile
# Añadido:
RUN chmod +x entrypoint.sh
CMD ["./entrypoint.sh"]
```

**Antes:**
- Ejecutaba directamente `flutter run`

**Después:**
- Ejecuta el script `entrypoint.sh` que corre pruebas primero

### 2. docker-compose.yml
**Cambios:**
```yaml
# Añadido servicio alternativo para desarrollo:
bored-games-dev:
  # ... configuración
  command: ["./entrypoint-no-tests.sh"]
```

**Nuevo comportamiento:**
- `docker-compose up` → Ejecuta pruebas
- `docker-compose up bored-games-dev` → Sin pruebas

### 3. .github/workflows/deploy.yml
**Cambios:**
```yaml
# Añadido nuevo job:
test:
  name: Run Tests
  steps:
    - name: Run unit tests
      run: flutter test

# Modificado:
analyze:
  needs: test  # Ahora depende de que las pruebas pasen
```

**Nuevo flujo CI/CD:**
1. ✅ Ejecutar pruebas
2. ✅ Analizar código
3. ✅ Build
4. ✅ Deploy

### 4. README.md
**Cambios:**
- Actualizado con nueva información sobre pruebas
- Añadidas instrucciones para ejecutar con/sin pruebas
- Enlaces a documentación de testing
- Información sobre Boss System y FPS View

---

## 🚀 Cómo Usar

### Desarrollo Local con Docker

#### Opción 1: Con Pruebas (Recomendado)
```bash
docker-compose up --build
```

**Resultado:**
```
🧪 Ejecutando pruebas unitarias...
✅ Todas las pruebas pasaron!
🚀 Iniciando aplicación...
```

#### Opción 2: Sin Pruebas (Desarrollo Rápido)
```bash
docker-compose up bored-games-dev --build
```

**Resultado:**
```
⚠️ Modo desarrollo - sin pruebas
🚀 Iniciando aplicación directamente...
```

### Desarrollo Local sin Docker

```bash
cd flutter_app

# Ejecutar pruebas manualmente
flutter test

# Ejecutar la app
flutter run -d chrome
```

### GitHub Actions (Automático)

Cuando haces push a `main`:
1. ✅ Se ejecutan todas las pruebas
2. ✅ Se analiza el código
3. ✅ Se construye la app
4. ✅ Se despliega a GitHub Pages

Si las pruebas fallan, el pipeline se detiene.

---

## 📊 Pruebas Incluidas

El proyecto ahora tiene **600+ pruebas** que cubren:

### 1. Boss System
- ✅ 11 tipos de jefes (10 world bosses + mini-boss)
- ✅ Sistema de 4 fases
- ✅ Mecánicas únicas por jefe
- ✅ Daño y muerte
- ✅ Habilidades y callbacks

**Archivo:** `test/boss_test.dart`

### 2. Enemy Manager Integration
- ✅ Lógica de spawn de jefes
- ✅ Escalado de estadísticas
- ✅ Recompensas y callbacks
- ✅ Estado de jefes

**Archivo:** `test/enemy_manager_boss_test.dart`

### 3. Boss Health Bar
- ✅ Seguimiento de jefes
- ✅ Colores de fase
- ✅ Animaciones
- ✅ Rendimiento

**Archivo:** `test/boss_health_bar_test.dart`

### 4. FPS View Component
- ✅ Vista FPS para 4 torres
- ✅ Modo BOOST
- ✅ Efectos de retroceso
- ✅ Renderizado de armas

**Archivo:** `test/fps_view_test.dart`

### 5. Integration Tests
- ✅ Encuentros completos con jefes
- ✅ Integración de sistemas
- ✅ Secuencias de múltiples jefes

**Archivo:** `test/integration/boss_system_integration_test.dart`

---

## 🎯 Ventajas de Esta Configuración

### 1. Calidad Garantizada
- ✅ No se puede deployar código roto
- ✅ Las pruebas se ejecutan antes de cada inicio
- ✅ Feedback inmediato sobre fallos

### 2. Flexible
- ✅ Modo con pruebas para producción
- ✅ Modo sin pruebas para desarrollo rápido
- ✅ Fácil de alternar entre modos

### 3. CI/CD Ready
- ✅ GitHub Actions ejecuta pruebas automáticamente
- ✅ Pipeline se detiene si las pruebas fallan
- ✅ Deploy solo si todo pasa

### 4. Bien Documentado
- ✅ README actualizado
- ✅ Guía específica de Docker testing
- ✅ Resumen de pruebas disponible

---

## 📚 Documentación Relacionada

- [DOCKER_TESTING.md](DOCKER_TESTING.md) - Guía completa de Docker con pruebas
- [TEST_SUMMARY.md](flutter_app/TEST_SUMMARY.md) - Resumen de todas las pruebas
- [BOSS_GUIDE.md](flutter_app/docs/BOSS_GUIDE.md) - Sistema de jefes
- [FPS_VIEW_GUIDE.md](flutter_app/docs/FPS_VIEW_GUIDE.md) - Sistema FPS view
- [README.md](README.md) - Documentación principal del proyecto

---

## 🐛 Solución de Problemas

### Las pruebas fallan al ejecutar docker-compose up

**Solución 1:** Verifica localmente
```bash
cd flutter_app
flutter test
```

**Solución 2:** Usa el modo desarrollo
```bash
docker-compose up bored-games-dev --build
```

**Solución 3:** Revisa los logs
```bash
docker logs bored_games_flutter
```

### Error de permisos con entrypoint.sh

```bash
cd flutter_app
chmod +x entrypoint.sh
chmod +x entrypoint-no-tests.sh
docker-compose build --no-cache
```

### Quiero ejecutar solo algunas pruebas

```bash
# Dentro del contenedor:
docker exec bored_games_flutter flutter test test/boss_test.dart

# O localmente:
cd flutter_app
flutter test test/boss_test.dart
```

---

## ✨ Próximos Pasos

1. **Ejecuta las pruebas**
   ```bash
   docker-compose up --build
   ```

2. **Verifica que todo funciona**
   - Deberías ver todas las pruebas pasando
   - La app debería iniciar automáticamente
   - Accede a http://localhost:3001

3. **Prueba el juego**
   - Juega niveles para ver los jefes
   - Activa el modo FPS en las torres
   - Verifica que el modo BOOST funciona con jefes

4. **Push a GitHub**
   ```bash
   git add .
   git commit -m "Add automated testing to Docker and CI/CD"
   git push origin main
   ```

5. **Verifica GitHub Actions**
   - Ve a la pestaña "Actions" en GitHub
   - Verifica que las pruebas pasen en el pipeline

---

## 📝 Resumen de Comandos

```bash
# Con pruebas (producción/deploy)
docker-compose up --build

# Sin pruebas (desarrollo rápido)
docker-compose up bored-games-dev --build

# Ejecutar pruebas localmente
cd flutter_app && flutter test

# Ver logs
docker logs bored_games_flutter

# Detener
docker-compose down

# Rebuild completo
docker-compose build --no-cache
```

---

*Configuración completada: 2026-01-13*
*Archivos creados: 4*
*Archivos modificados: 4*
*Total de pruebas: 600+*
