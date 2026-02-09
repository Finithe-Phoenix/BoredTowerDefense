# 🚀 CI/CD Setup - Publicación Automática a Play Store

Este documento explica cómo configurar la publicación automática de tu aplicación a Google Play Store usando GitHub Actions.

## 📋 Tabla de Contenidos

1. [Prerequisitos](#prerequisitos)
2. [Configuración del Keystore](#configuración-del-keystore)
3. [Configuración de Play Store](#configuración-de-play-store)
4. [Configuración de GitHub Secrets](#configuración-de-github-secrets)
5. [Workflows Disponibles](#workflows-disponibles)
6. [Cómo Publicar](#cómo-publicar)
7. [Troubleshooting](#troubleshooting)

---

## 📦 Prerequisitos

- [ ] Cuenta de Google Play Console
- [ ] Aplicación creada en Play Console
- [ ] Keystore de firma para Android
- [ ] Cuenta de servicio de Google Cloud con permisos de Play Console

---

## 🔐 Configuración del Keystore

### 1. Crear un Keystore (si no tienes uno)

```bash
cd flutter_app/android/app
keytool -genkey -v -keystore upload-keystore.jks -keyalg RSA -keysize 2048 -validity 10000 -alias upload
```

**IMPORTANTE:** Guarda en un lugar seguro:
- La contraseña del keystore
- La contraseña de la key
- El alias de la key
- El archivo `upload-keystore.jks`

### 2. Convertir Keystore a Base64

Para GitHub Actions, necesitas convertir el keystore a Base64:

```bash
# En macOS/Linux:
base64 -i flutter_app/android/app/upload-keystore.jks | pbcopy

# O usar archivo:
base64 -i flutter_app/android/app/upload-keystore.jks > keystore.base64.txt
```

Esto copiará el contenido en Base64 al portapapeles o archivo.

---

## 🎮 Configuración de Play Store

### 1. Crear una Cuenta de Servicio

1. Ve a [Google Cloud Console](https://console.cloud.google.com)
2. Selecciona o crea un proyecto
3. Ve a **IAM & Admin** > **Service Accounts**
4. Click en **Create Service Account**
5. Dale un nombre: `github-actions-deploy`
6. Click **Create and Continue**
7. No es necesario dar roles en este paso
8. Click **Done**

### 2. Crear JSON Key para la Cuenta de Servicio

1. En la lista de Service Accounts, encuentra la que creaste
2. Click en los 3 puntos (⋮) > **Manage keys**
3. Click **Add Key** > **Create new key**
4. Selecciona **JSON**
5. Click **Create** - se descargará un archivo JSON

### 3. Dar Permisos en Play Console

1. Ve a [Google Play Console](https://play.google.com/console)
2. Selecciona tu aplicación
3. Ve a **Setup** > **API access**
4. En la sección **Service accounts**, click **Link service account**
5. Busca y selecciona la cuenta de servicio que creaste
6. Click **Link service account**
7. En **Account permissions**, dale los siguientes permisos:
   - **Release manager** (para publicar)
   - **Release to production, exclude devices, and use Play App Signing**

### 4. Convertir Service Account JSON a Base64

```bash
# En macOS/Linux:
base64 -i /path/to/downloaded-service-account.json | pbcopy

# O usar archivo:
base64 -i /path/to/downloaded-service-account.json > service-account.base64.txt
```

---

## 🔑 Configuración de GitHub Secrets

Ve a tu repositorio en GitHub:
**Settings** > **Secrets and variables** > **Actions** > **New repository secret**

Crea los siguientes secrets:

| Secret Name | Descripción | Cómo Obtenerlo |
|-------------|-------------|----------------|
| `KEYSTORE_BASE64` | Keystore codificado en Base64 | Ver paso [Convertir Keystore a Base64](#2-convertir-keystore-a-base64) |
| `KEYSTORE_PASSWORD` | Contraseña del keystore | La que usaste al crear el keystore |
| `KEY_ALIAS` | Alias de la key | El alias que usaste (por defecto `upload`) |
| `KEY_PASSWORD` | Contraseña de la key | La que usaste al crear la key |
| `PLAYSTORE_SERVICE_ACCOUNT_JSON` | Service Account JSON en Base64 | Ver paso [Convertir Service Account JSON a Base64](#4-convertir-service-account-json-a-base64) |

### Ejemplo de configuración:

```
KEYSTORE_BASE64=<tu contenido base64 del keystore>
KEYSTORE_PASSWORD=tu_password_super_secreto
KEY_ALIAS=upload
KEY_PASSWORD=tu_key_password_super_secreto
PLAYSTORE_SERVICE_ACCOUNT_JSON=<tu service account json en base64>
```

---

## 🔄 Workflows Disponibles

### 1. **CI - Tests** (`.github/workflows/ci.yml`)

Se ejecuta automáticamente en:
- Push a `main` o `develop`
- Pull Requests a `main` o `develop`

**Acciones:**
- ✅ Ejecuta tests
- ✅ Verifica formato del código
- ✅ Analiza el código
- ✅ Construye APK de Android
- ✅ Construye iOS (en macOS)
- ✅ Sube cobertura de tests a Codecov

### 2. **Deploy to Play Store** (`.github/workflows/deploy-playstore.yml`)

Se ejecuta cuando:
- Haces push a `main`
- Creas un tag con formato `v*` (ej: `v1.0.0`)
- Lo ejecutas manualmente desde GitHub Actions

**Acciones:**
- ✅ Ejecuta tests
- ✅ Construye App Bundle (.aab)
- ✅ Firma la app con tu keystore
- ✅ Sube automáticamente a Play Store
- ✅ Publica en el track seleccionado (internal/alpha/beta/production)

---

## 🚀 Cómo Publicar

### Opción 1: Push a Main (Publicación Interna)

```bash
git add .
git commit -m "feat: nueva versión con mejoras épicas"
git push origin main
```

Esto publicará automáticamente a **internal track** en Play Store.

### Opción 2: Crear un Release Tag (Recomendado)

```bash
# Incrementa la versión en pubspec.yaml primero
# version: 1.0.1+2

git add flutter_app/pubspec.yaml
git commit -m "chore: bump version to 1.0.1"
git tag v1.0.1
git push origin main --tags
```

Esto publicará automáticamente a **internal track**.

### Opción 3: Ejecución Manual (Control Total)

1. Ve a tu repositorio en GitHub
2. Click en **Actions**
3. Selecciona **Deploy to Play Store**
4. Click en **Run workflow**
5. Selecciona el track de publicación:
   - `internal` - Solo testers internos
   - `alpha` - Testers alfa
   - `beta` - Testers beta
   - `production` - PRODUCCIÓN (usuarios finales)
6. Click **Run workflow**

---

## 📊 Monitoreo del Deployment

### Ver el Progreso

1. Ve a la pestaña **Actions** en GitHub
2. Click en el workflow que está corriendo
3. Verás el progreso en tiempo real

### Verificar en Play Console

1. Ve a [Play Console](https://play.google.com/console)
2. Selecciona tu aplicación
3. Ve a **Release** > **Testing** (o **Production** según el track)
4. Verás la nueva versión en proceso o publicada

---

## 🐛 Troubleshooting

### Error: "Keystore not found"

**Solución:** Verifica que `KEYSTORE_BASE64` esté correctamente configurado en GitHub Secrets.

```bash
# Verifica que el base64 esté correcto:
echo "tu_base64_string" | base64 --decode > test-keystore.jks
```

### Error: "Service account not authorized"

**Solución:**
1. Verifica que la cuenta de servicio esté vinculada en Play Console
2. Verifica que tenga permisos de **Release manager**
3. Espera 24 horas después de crear la cuenta (a veces toma tiempo propagarse)

### Error: "Version code must be higher"

**Solución:** Incrementa el version code en `flutter_app/pubspec.yaml`:

```yaml
version: 1.0.1+2  # El número después del + es el version code
```

### Error: "Package name mismatch"

**Solución:** Verifica que el `packageName` en `deploy-playstore.yml` coincida con el de tu app:

```yaml
packageName: com.example.bored_tower_defense  # Cambia esto al tuyo
```

Puedes verificar tu package name en:
```
flutter_app/android/app/src/main/AndroidManifest.xml
```

### Build Falla en GitHub Actions

**Solución:**
1. Verifica que los tests pasen localmente:
   ```bash
   cd flutter_app
   flutter test
   ```
2. Verifica que la build funcione localmente:
   ```bash
   flutter build appbundle --release
   ```
3. Revisa los logs detallados en GitHub Actions

---

## 📝 Notas Importantes

### Incrementar Versiones

Cada publicación requiere un version code más alto. En `flutter_app/pubspec.yaml`:

```yaml
# ANTES
version: 1.0.0+1

# DESPUÉS (incrementa el número después del +)
version: 1.0.0+2
```

### Tracks de Publicación

- **internal**: Solo para tu equipo de desarrollo (máximo 100 testers)
- **alpha**: Testers alfa (usuarios de prueba cerrada)
- **beta**: Testers beta (usuarios de prueba abierta)
- **production**: Todos los usuarios en Play Store

### Tiempos de Publicación

- **Internal/Alpha/Beta**: Inmediato (5-10 minutos)
- **Production**: Puede tomar varias horas para revisión de Google

### Release Notes

Crea archivos de release notes en:
```
flutter_app/android/whatsnew/
  whatsnew-en-US
  whatsnew-es-ES
```

Ejemplo de contenido:
```
✨ Nuevo menú de mejoras épico
🎨 Diseño TRON mejorado
🐛 Corrección de bugs
⚡ Mejoras de rendimiento
```

---

## 🎯 Checklist Rápido

Antes de tu primera publicación:

- [ ] Keystore creado y guardado de forma segura
- [ ] Service account creada en Google Cloud
- [ ] Service account vinculada en Play Console con permisos
- [ ] Todos los secrets configurados en GitHub
- [ ] Package name correcto en `deploy-playstore.yml`
- [ ] Version incrementada en `pubspec.yaml`
- [ ] App creada en Play Console
- [ ] Tests pasando localmente
- [ ] Build exitosa localmente

---

## 🆘 Soporte

Si tienes problemas:

1. Revisa la sección [Troubleshooting](#troubleshooting)
2. Revisa los logs en GitHub Actions
3. Verifica la documentación oficial:
   - [Flutter Deployment](https://docs.flutter.dev/deployment/android)
   - [Play Console Help](https://support.google.com/googleplay/android-developer)
   - [GitHub Actions](https://docs.github.com/en/actions)

---

## 🎉 ¡Listo!

Una vez configurado, solo necesitas hacer push a tu repositorio y GitHub Actions se encargará del resto:

```bash
git add .
git commit -m "feat: amazing new feature"
git push origin main
```

Y en unos minutos tu app estará publicada en Play Store! 🚀
