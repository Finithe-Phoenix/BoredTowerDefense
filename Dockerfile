FROM ghcr.io/cirruslabs/flutter:3.22.1

ARG APP_ENV=dev
ENV APP_ENV=${APP_ENV}

WORKDIR /app

COPY flutter_app/ ./flutter_app/
WORKDIR /app/flutter_app

RUN flutter pub get

EXPOSE 8080

CMD ["sh", "-c", "flutter run -d web-server --web-port 8080 --web-hostname 0.0.0.0 --dart-define=APP_ENV=$APP_ENV"]
