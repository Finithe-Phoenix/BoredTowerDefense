#!/bin/bash

echo "🔧 Configurando permisos de scripts..."

cd flutter_app

# Hacer ejecutables los scripts de entrypoint
chmod +x entrypoint.sh
chmod +x entrypoint-no-tests.sh

echo "✅ Permisos configurados correctamente!"
echo ""
echo "Puedes ejecutar:"
echo "  docker-compose up --build    # Con pruebas"
echo "  docker-compose up bored-games-dev --build    # Sin pruebas"
