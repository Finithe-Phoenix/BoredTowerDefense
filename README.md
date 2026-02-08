# Neon Defense - Tower Defense Game

A Tron-style neon tower defense game built with Flutter + Flame engine.

![Flutter](https://img.shields.io/badge/Flutter-3.22.1-blue) ![Flame](https://img.shields.io/badge/Flame-1.17.0-orange) ![License](https://img.shields.io/badge/License-MIT-green)

## Features

- **4 Tower Types**: Pulse Archer, Circuit Cannon, Phase Mage, Glimmer Field
- **3 Enemy Types**: Runner, Overloaded, Juggernaut
- **Boss System**: 10 unique world bosses + mini-bosses with special mechanics
- **FPS View Mode**: First-person perspective for each tower with BOOST mode
- **Wave System**: Progressive difficulty with modifiers (Overload, Juggernaut, Mixed waves)
- **Neon Pulse Ability**: Area slow effect (SPACE key)
- **100 Campaign Levels**: 10 worlds with progressive unlocking and star ratings
- **Settings**: Audio, graphics, particle intensity controls
- **Neon Tron Aesthetic**: Glowing UI, animated grid backgrounds, particle effects
- **Comprehensive Testing**: 600+ unit and integration tests

## Story Mode
Unlock the lore by selecting **Story Mode** from the main menu. Each chapter chronicles Commander Lira Kestrel’s fight to restore the fractured Grid, describing the factions, abilities, and wave modifiers you face; completing deeper waves unlocks glowing beacons and new narrative beats as the Campaign progresses.

## Quick Start

### Using Docker (Recommended)

```bash
# Build and run (includes automated testing)
docker compose up --build

# Access the game
open http://localhost:3001

# Skip tests for faster development
docker compose up bored-games-dev --build
```

> 📋 **Note**: By default, all unit tests (600+ test cases) run automatically before starting the app. See [DOCKER_TESTING.md](DOCKER_TESTING.md) for details.

### Local Development

```bash
cd flutter_app

# Install dependencies
flutter pub get

# Run tests
flutter test

# Run in debug mode
flutter run -d chrome

# Build for production
flutter build web --release --web-renderer canvaskit
```

## Game Controls

| Action | Control |
|--------|---------|
| Place Tower | Click on valid cell |
| Select Tower Type | Click tower buttons in HUD |
| Activate Neon Pulse | SPACE key |
| Start Wave | Click "Start Wave" button |
| Pause Game | ESC key |

## Project Structure

```
flutter_app/
├── lib/
│   ├── main.dart                 # App entry point
│   └── src/
│       ├── bloc/                 # State management (Bloc/Cubit)
│       │   ├── game/             # GameBloc for gameplay state
│       │   └── settings/         # SettingsCubit for preferences
│       ├── game/                 # Flame game components
│       │   ├── components/       # Grid, pulse effects
│       │   ├── effects/          # Particle system
│       │   ├── entities/         # Enemy, Tower, Projectile
│       │   ├── hud/              # In-game UI
│       │   ├── managers/         # Enemy, Tower, Bullet managers
│       │   └── world/            # Tiled map integration
│       ├── models/               # Data models (LevelConfig)
│       ├── services/             # Audio, Storage, Level services
│       └── ui/                   # Flutter UI screens
│           ├── overlays/         # Pause, Victory, GameOver
│           ├── screens/          # Menu, LevelSelect, Settings
│           ├── theme/            # Neon colors and styles
│           └── widgets/          # Reusable neon components
└── assets/
    └── tiles/maps/               # Tiled TMX map files
```

## Deployment

### GitHub Pages (Automatic)

Push to `main` branch triggers automatic deployment via GitHub Actions.

```bash
git push origin main
# Game will be available at: https://yourusername.github.io/BoredGames/
```

### Manual Deployment

```bash
cd flutter_app
flutter build web --release --web-renderer canvaskit --base-href "/your-base-path/"

# Deploy the contents of flutter_app/build/web/
```

### Build Android APK (Docker)

Build the APK using Docker without needing Android Studio or local Flutter SDK:

```powershell
cd flutter_app
docker build -f Dockerfile.apk --output build-output .
```

Los APKs se generan en la carpeta `build-output/`:

| Archivo | Descripcion |
|---------|-------------|
| `bored-games-release.apk` | APK universal (todos los dispositivos) |
| `app-arm64-v8a-release.apk` | ARM 64-bit (telefonos modernos) |
| `app-armeabi-v7a-release.apk` | ARM 32-bit (telefonos antiguos) |
| `app-x86_64-release.apk` | x86_64 (emuladores) |

> **Nota**: El primer build tarda ~15 minutos. Los siguientes son mas rapidos gracias al cache de Docker.

## Development Guide

See [Guide.md](Guide.md) for the complete development roadmap and phase documentation.

### Testing

The project includes comprehensive test coverage (600+ tests). See [TEST_SUMMARY.md](flutter_app/TEST_SUMMARY.md) for details.

```bash
# Run all tests
flutter test

# Run specific test file
flutter test test/boss_test.dart

# Run with coverage
flutter test --coverage
```

### Coverage Summary + HTML (Docker Friendly)

PowerShell summary + HTML report (prints total, passed, failed, skipped, and success %):

```powershell
.\scripts\coverage.ps1
```

Docker-only run (no local Flutter install). This generates `flutter_app/coverage/lcov.info`:

```bash
docker compose -f flutter_app/docker-compose.yml run --rm flutter-dev flutter test --coverage --machine > flutter_app/coverage/test-machine.jsonl
```

Generate HTML locally if you have `genhtml` (from `lcov`) installed:

```bash
genhtml flutter_app/coverage/lcov.info -o flutter_app/coverage/html
```

### Boss System

See [BOSS_GUIDE.md](flutter_app/docs/BOSS_GUIDE.md) for details on all 10 world bosses and their mechanics.

### FPS View System

See [FPS_VIEW_GUIDE.md](flutter_app/docs/FPS_VIEW_GUIDE.md) for implementation details of the first-person tower view system.

### Adding New Tower Types

1. Add entry to `TowerType` enum in `lib/src/game/entities/tower.dart`
2. Define stats (range, damage, fireRate, cost, color, projectileSpeed, slowAmount, slowDuration)
3. Add selection button in `lib/src/game/hud/hud_component.dart`

### Adding New Enemy Types

1. Add entry to `EnemyType` enum in `lib/src/game/entities/enemy.dart`
2. Define stats (health multiplier, speed multiplier, color, size)
3. Update wave spawning in `lib/src/game/managers/enemy_manager.dart`

### Adding New Levels

1. Create TMX map file in `assets/tiles/maps/`
2. Add asset path to `pubspec.yaml`
3. Add level config in `lib/src/services/level_service.dart`

## Tech Stack

- **Flutter 3.22.1** - UI framework
- **Flame 1.17.0** - Game engine
- **flame_tiled** - Tiled map integration
- **flutter_bloc** - State management
- **Docker** - Development environment

## License

MIT License
