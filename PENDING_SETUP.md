# 📋 Configuración Pendiente - Play Store Deployment

## ✅ Lo que YA está Completado

### 1. **Código y Configuración** ✅
- ✅ Menús épicos estilo TRON rediseñados
- ✅ Package name: `com.boredgames.towerdefense`
- ✅ Estructura Android completa generada
- ✅ Keystore creado: `flutter_app/android/app/upload-keystore.jks`
- ✅ Keystore en Base64: `~/Desktop/keystore-base64.txt`
- ✅ Tests: 12,233 pasados (99.94% éxito)
- ✅ Cobertura: 65.11%

### 2. **CI/CD Workflows** ✅
- ✅ `.github/workflows/ci.yml` - Tests automáticos
- ✅ `.github/workflows/deploy-playstore.yml` - Publicación automática
- ✅ Documentación completa (CICD_SETUP.md, QUICKSTART_CICD.md)
- ✅ Release notes (whatsnew-en-US, whatsnew-es-ES)

### 3. **Archivos de Seguridad** ✅
- ✅ `.gitignore` actualizado para proteger secrets
- ✅ Keystore NO commiteado (seguro)

---

## ⏳ Pendiente - Cuando tengas las Cuentas

### Paso 1: Crear App en Play Console
1. Ve a: https://play.google.com/console
2. Crea una nueva aplicación
3. Completa la información básica
4. **Package name**: `com.boredgames.towerdefense` (debe coincidir exactamente)

### Paso 2: Crear Service Account en Google Cloud

**2.1 - Crear la cuenta:**
1. Ve a: https://console.cloud.google.com/iam-admin/serviceaccounts
2. Selecciona el proyecto vinculado a tu app de Play Store
3. Click **"Create Service Account"**
4. Nombre: `github-actions-deploy`
5. Click **"Create and Continue"** → **"Done"**

**2.2 - Descargar JSON key:**
1. Click en los 3 puntos (⋮) del service account
2. **"Manage keys"**
3. **"Add Key"** → **"Create new key"** → **JSON**
4. Se descargará automáticamente

**2.3 - Convertir a Base64:**
```bash
# Reemplaza NOMBRE-DEL-ARCHIVO.json con el nombre real
base64 -i ~/Downloads/NOMBRE-DEL-ARCHIVO.json | pbcopy
pbpaste > ~/Desktop/service-account-base64.txt
```

### Paso 3: Vincular Service Account en Play Console

1. Ve a Play Console: https://play.google.com/console
2. Selecciona tu app
3. **Setup** → **API access**
4. Click **"Link service account"**
5. Selecciona `github-actions-deploy@...`
6. Dale permisos: **"Admin"** o **"Release manager"**
7. Click **"Invite user"**

⚠️ **IMPORTANTE**: Los permisos pueden tardar hasta 24 horas en activarse.

### Paso 4: Configurar GitHub Secrets

1. Ve a: https://github.com/Finithe-Phoenix/BoredTowerDefense/settings/secrets/actions
2. Click **"New repository secret"**
3. Crea estos 5 secrets:

| Nombre | Valor | Ubicación |
|--------|-------|-----------|
| `KEYSTORE_BASE64` | Contenido de `~/Desktop/keystore-base64.txt` | Ya lo tienes |
| `KEYSTORE_PASSWORD` | La contraseña que usaste al crear el keystore | La que elegiste |
| `KEY_ALIAS` | `upload` | Fijo |
| `KEY_PASSWORD` | La misma contraseña del keystore | La que elegiste |
| `PLAYSTORE_SERVICE_ACCOUNT_JSON` | Contenido de `~/Desktop/service-account-base64.txt` | Cuando lo crees |

### Paso 5: Primera Publicación Manual (Opcional)

Antes de usar CI/CD, sube una versión manualmente a Play Console:
- Esto es necesario para activar la app en Play Store
- Después, GitHub Actions podrá publicar automáticamente

1. Construye el AAB localmente (si tienes Flutter instalado)
2. O sube un APK de debug para testing inicial
3. Una vez publicada manualmente, GitHub Actions puede tomar el control

### Paso 6: Activar GitHub Actions

Una vez configurados los secrets:

```bash
cd /Users/danieleduardogonzalezramirez/Documents/GitHub/BoredTowerDefense

# Incrementa la versión en flutter_app/pubspec.yaml
# version: 1.0.1+2

git add .
git commit -m "Release v1.0.1"
git push origin main
```

**¡GitHub Actions automáticamente construirá y publicará!**

---

## 📂 Archivos Importantes que YA Tienes

### En tu Desktop:
- ✅ `~/Desktop/keystore-base64.txt` - Keystore en Base64 (para GitHub secret)
- ⏳ `~/Desktop/service-account-base64.txt` - Pendiente (cuando crees el service account)

### En el proyecto:
- ✅ `flutter_app/android/app/upload-keystore.jks` - Keystore original
- ✅ `.github/workflows/deploy-playstore.yml` - Workflow de publicación
- ✅ `QUICKSTART_CICD.md` - Guía rápida
- ✅ `CICD_SETUP.md` - Documentación completa

---

## 🎯 Checklist Rápido

Cuando tengas las cuentas listas, completa estos pasos en orden:

- [ ] Crear app en Play Console
- [ ] Crear Service Account en Google Cloud
- [ ] Descargar JSON key y convertir a Base64
- [ ] Vincular Service Account en Play Console
- [ ] Configurar los 5 GitHub Secrets
- [ ] Esperar 24 horas (permisos de Service Account)
- [ ] Publicación manual inicial (opcional)
- [ ] Git push → ¡Publicación automática!

---

## 📞 Recursos

- **Guía Rápida**: [QUICKSTART_CICD.md](QUICKSTART_CICD.md)
- **Guía Completa**: [CICD_SETUP.md](CICD_SETUP.md)
- **Resumen**: [DEPLOYMENT_SUMMARY.md](DEPLOYMENT_SUMMARY.md)
- **Flutter Deployment Docs**: https://docs.flutter.dev/deployment/android
- **Play Console Help**: https://support.google.com/googleplay/android-developer

---

## 💡 Notas Importantes

### Seguridad
- **NUNCA** commitees los archivos `.jks`, `.keystore`, o `*-service-account.json`
- Ya están en `.gitignore`, pero ten cuidado
- Los secrets de GitHub están encriptados y son seguros

### Versiones
- Cada publicación necesita incrementar el version code en `pubspec.yaml`
- Formato: `version: 1.0.0+1` (el número después del `+` debe incrementarse)

### Troubleshooting
- Si el Service Account no funciona después de 24h, verifica los permisos en Play Console
- Si el build falla, revisa los logs en GitHub Actions
- Si necesitas ayuda, consulta `CICD_SETUP.md` sección Troubleshooting

---

## 🎉 ¡Todo está Listo para Cuando Tengas las Cuentas!

Solo necesitas:
1. Crear las cuentas de Google (Play Console + Cloud)
2. Configurar los 5 secrets en GitHub
3. Hacer `git push`

¡Y tu juego se publicará automáticamente! 🚀
