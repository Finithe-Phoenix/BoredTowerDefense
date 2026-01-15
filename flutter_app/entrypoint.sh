#!/bin/bash

echo "=========================================="
echo "  🧪 Ejecutando pruebas unitarias..."
echo "=========================================="
echo ""

# Ejecutar pruebas (el resultado no detendrá el script)
flutter test

echo ""
echo "=========================================="
echo "  🏁 Pruebas finalizadas."
echo "=========================================="
echo ""
echo "🚀 Iniciando aplicación..."
echo ""

# Iniciar la aplicación independientemente del resultado de las pruebas
flutter run -d web-server --web-port 8080 --web-hostname 0.0.0.0 --dart-define=APP_ENV=$APP_ENV
