# Bored Games Flutter + Docker

Este repositorio contiene una aplicacion Flutter minima junto con una configuracion de Docker para desarrollar y ejecutar la aplicacion dentro de un contenedor.

## Estructura
- `flutter_app/`: codigo Flutter + Flame (`pubspec.yaml`, `lib/main.dart`, `lib/src/game/**`, `web/`).
- `Dockerfile`: imagen basada en Flutter 3.22.1 que instala dependencias y ejecuta la app para web.
- `docker-compose.yml`: levanta el contenedor expuesto en el puerto `3001` (host) -> `8080` (contenedor).
- `.dockerignore` & `.gitignore`: protegen archivos temporales y especificos de Flutter.

## Uso

1. **Construir la imagen**  
   ```bash
   docker build -t bored-games-flutter .
   ```

2. **Ejecutar con Docker Compose**  
   ```bash
   docker compose up
   ```
   Esto compila la aplicacion y la sirve por `http://localhost:3001` (host).

3. **Desarrollo iterativo**  
   El volumen montado (`./flutter_app:/app/flutter_app`) refresca los cambios al codigo sin reconstruir la imagen. Solo reinicia el servicio si modificas dependencias o archivos agregados al build.

4. **Limpiar**  
   ```bash
   docker compose down
   ```

## Notas
- La imagen usa el canal `stable` de Flutter y prepara la app para `web-server`. Si necesitas Android/iOS, ajusta el comando en el `Dockerfile`.
- Puedes abrir `flutter_app/lib/main.dart` para expandir la interfaz.
