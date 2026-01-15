#!/bin/bash

echo "=========================================="
echo "  ⚠️  Modo desarrollo - sin pruebas"
echo "=========================================="
echo ""
echo "🚀 Iniciando aplicación directamente..."
echo ""

# Iniciar la aplicación sin ejecutar pruebas
flutter run -d web-server --web-port 8080 --web-hostname 0.0.0.0 --dart-define=APP_ENV=$APP_ENV
