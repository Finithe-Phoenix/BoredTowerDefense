# 🚀 Quick Start - CI/CD en 10 Minutos

Esta guía te ayudará a configurar rápidamente la publicación automática a Play Store.

## ⚡ Pasos Rápidos

### 1️⃣ Crear Keystore (2 minutos)

```bash
cd flutter_app/android/app
keytool -genkey -v -keystore upload-keystore.jks -keyalg RSA -keysize 2048 -validity 10000 -alias upload
```

**Guarda estos datos en un lugar seguro:**
- Keystore password: `_____________`
- Key password: `_____________`
- Alias: `upload`

### 2️⃣ Convertir Keystore a Base64 (30 segundos)

```bash
# macOS/Linux:
base64 -i flutter_app/android/app/upload-keystore.jks | pbcopy
```

El contenido ya está en tu portapapeles! 📋

### 3️⃣ Crear Service Account (3 minutos)

1. Ve a: https://console.cloud.google.com/iam-admin/serviceaccounts
2. Click **Create Service Account**
3. Nombre: `github-actions-deploy`
4. Click **Create and Continue** > **Done**
5. Click en los 3 puntos (⋮) > **Manage keys**
6. Click **Add Key** > **Create new key** > **JSON**
7. Descarga el archivo JSON

### 4️⃣ Convertir Service Account a Base64 (30 segundos)

```bash
base64 -i ~/Downloads/nombre-del-archivo.json | pbcopy
```

Ya está en tu portapapeles! 📋

### 5️⃣ Vincular Service Account en Play Console (2 minutos)

1. Ve a: https://play.google.com/console
2. Selecciona tu app
3. **Setup** > **API access**
4. Click **Link service account**
5. Selecciona `github-actions-deploy@...`
6. Dale permisos: **Release manager**

### 6️⃣ Configurar GitHub Secrets (2 minutos)

Ve a tu repo en GitHub: **Settings** > **Secrets** > **Actions**

Crea estos 5 secrets:

```
KEYSTORE_BASE64 = <pega el contenido del paso 2>
KEYSTORE_PASSWORD = <tu password del paso 1>
KEY_ALIAS = upload
KEY_PASSWORD = <tu key password del paso 1>
PLAYSTORE_SERVICE_ACCOUNT_JSON = <pega el contenido del paso 4>
```

### 7️⃣ Actualizar Package Name (1 minuto)

Edita `.github/workflows/deploy-playstore.yml`:

```yaml
packageName: com.tu_empresa.tu_app  # Cambia esto
```

### 8️⃣ ¡Publicar! (1 segundo)

```bash
git add .
git commit -m "feat: configuración CI/CD completa"
git push origin main
```

## ✅ Verificación

1. Ve a **Actions** en GitHub
2. Deberías ver el workflow corriendo
3. En 5-10 minutos, tu app estará en Play Console!

## 🎯 Próximas Publicaciones

Solo necesitas:

```bash
# Incrementa la versión
# en flutter_app/pubspec.yaml: version: 1.0.1+2

git add .
git commit -m "feat: nueva característica épica"
git push
```

¡Y listo! GitHub Actions hace el resto automáticamente 🚀

---

## 📚 Documentación Completa

Para más detalles, lee: [CICD_SETUP.md](./CICD_SETUP.md)

## 🆘 Ayuda Rápida

### ❌ Error: "Keystore not found"
```bash
# Verifica el secret:
echo "$KEYSTORE_BASE64" | base64 --decode > test.jks
```

### ❌ Error: "Service account not authorized"
- Espera 24h después de crear la cuenta
- Verifica permisos en Play Console

### ❌ Error: "Version code must be higher"
```yaml
# flutter_app/pubspec.yaml
version: 1.0.1+2  # Incrementa el número después del +
```

---

## 🎉 ¡Éxito!

Si todo salió bien, verás:
- ✅ Tests pasando en GitHub Actions
- ✅ Build exitosa
- ✅ App publicada en Play Store
- ✅ Notificación de éxito en GitHub

¡Felicidades! Ahora tienes CI/CD completamente automatizado 🎊
