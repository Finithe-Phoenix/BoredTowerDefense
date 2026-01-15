FROM ghcr.io/cirruslabs/flutter:3.22.1

ARG APP_ENV=dev
ENV APP_ENV=${APP_ENV}

WORKDIR /app

COPY flutter_app/ ./flutter_app/
WORKDIR /app/flutter_app

RUN flutter pub get

# Hacer el script ejecutable
RUN chmod +x entrypoint.sh

EXPOSE 8080

# Usar el script de entrypoint que ejecuta pruebas primero
CMD ["./entrypoint.sh"]
