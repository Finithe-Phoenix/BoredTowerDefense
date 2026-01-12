# Neon Defense - Tower Defense Game

A Tron-style neon tower defense game built with Flutter + Flame engine.

![Flutter](https://img.shields.io/badge/Flutter-3.22.1-blue) ![Flame](https://img.shields.io/badge/Flame-1.17.0-orange) ![License](https://img.shields.io/badge/License-MIT-green)

## Features

- **4 Tower Types**: Pulse Archer, Circuit Cannon, Phase Mage, Glimmer Field
- **3 Enemy Types**: Runner, Overloaded, Juggernaut
- **Wave System**: Progressive difficulty with modifiers (Overload, Juggernaut, Mixed waves)
- **Neon Pulse Ability**: Area slow effect (SPACE key)
- **8 Campaign Levels**: Progressive unlocking with star ratings
- **Settings**: Audio, graphics, particle intensity controls
- **Neon Tron Aesthetic**: Glowing UI, animated grid backgrounds, particle effects

## Story Mode
Unlock the lore by selecting **Story Mode** from the main menu. Each chapter chronicles Commander Lira Kestrel’s fight to restore the fractured Grid, describing the factions, abilities, and wave modifiers you face; completing deeper waves unlocks glowing beacons and new narrative beats as the Campaign progresses.

## Quick Start

### Using Docker (Recommended)

```bash
# Build and run
docker compose up --build

# Access the game
open http://localhost:3001
```

### Local Development

```bash
cd flutter_app

# Install dependencies
flutter pub get

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

## Development Guide

See [Guide.md](Guide.md) for the complete development roadmap and phase documentation.

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
