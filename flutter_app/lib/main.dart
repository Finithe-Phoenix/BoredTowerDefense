import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'src/bloc/settings/settings_cubit.dart';
import 'src/ui/theme/neon_theme.dart';
import 'src/ui/screens/loading_screen.dart';
import 'src/ui/screens/main_menu_screen.dart';
import 'src/ui/screens/level_select_screen.dart';
import 'src/ui/screens/game_screen.dart';
import 'src/ui/screens/settings_screen.dart';
import 'src/ui/screens/story_screen.dart';
import 'src/ui/screens/upgrades_screen.dart';
import 'src/ui/screens/benchmark_screen.dart';
import 'src/ui/screens/codex_screen.dart';
import 'src/ui/transitions/tron_page_route.dart';
import 'src/ui/widgets/tron_materialization_widget.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Services are now initialized in LoadingScreen
  runApp(const NeonDefenseApp());
}

class NeonDefenseApp extends StatelessWidget {
  const NeonDefenseApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider(create: (_) => SettingsCubit()),
      ],
      child: MaterialApp(
        title: 'Neon Defense',
        debugShowCheckedModeBanner: false,
        theme: NeonTheme.darkTheme,
        initialRoute: '/',
        onGenerateRoute: (settings) {
          switch (settings.name) {
            case '/':
              return MaterialPageRoute(
                builder: (_) => const LoadingScreen(),
              );
            case '/menu':
              // Main menu uses light cycle pattern for dramatic entry
              return TronPageRoute(
                builder: (_) => const MainMenuScreen(),
                primaryColor: NeonColors.cyan,
                secondaryColor: const Color(0xFFFF6600),
                pattern: TronPattern.lightCycle,
                transitionDuration: const Duration(milliseconds: 900),
              );
            case '/levels':
              // Level select uses hexagonal pattern
              return TronPageRoute(
                builder: (_) => const LevelSelectScreen(),
                primaryColor: NeonColors.magenta,
                secondaryColor: NeonColors.cyan,
                pattern: TronPattern.hexagonal,
                transitionDuration: const Duration(milliseconds: 850),
              );
            case '/game':
              final levelId = settings.arguments as int? ?? 1;
              // Game uses radial pattern for dramatic reveal
              return TronPageRoute(
                builder: (_) => GameScreen(levelId: levelId),
                primaryColor: NeonColors.cyan,
                secondaryColor: const Color(0xFFFF6600),
                pattern: TronPattern.radial,
                transitionDuration: const Duration(milliseconds: 1000),
              );
            case '/story':
              // Story uses grid pattern
              return TronPageRoute(
                builder: (_) => const StoryScreen(),
                primaryColor: NeonColors.purple,
                secondaryColor: NeonColors.cyan,
                pattern: TronPattern.grid,
                transitionDuration: const Duration(milliseconds: 800),
              );
            case '/settings':
              // Settings uses light cycle pattern
              return TronPageRoute(
                builder: (_) => const SettingsScreen(),
                primaryColor: NeonColors.blue,
                secondaryColor: NeonColors.cyan,
                pattern: TronPattern.lightCycle,
                transitionDuration: const Duration(milliseconds: 800),
              );
            case '/upgrades':
              // Upgrades uses hexagonal pattern
              return TronPageRoute(
                builder: (_) => const UpgradesScreen(),
                primaryColor: NeonColors.yellow,
                secondaryColor: NeonColors.orange,
                pattern: TronPattern.hexagonal,
                transitionDuration: const Duration(milliseconds: 850),
              );
            case '/benchmark':
              // Benchmark uses radial pattern with orange TRON color
              return TronPageRoute(
                builder: (_) => const BenchmarkScreen(),
                primaryColor: const Color(0xFFFF6600),
                secondaryColor: NeonColors.cyan,
                pattern: TronPattern.radial,
                transitionDuration: const Duration(milliseconds: 900),
              );
            case '/codex':
              // Codex/Lore uses grid pattern with mysterious colors
              return TronPageRoute(
                builder: (_) => const CodexScreen(),
                primaryColor: NeonColors.magenta,
                secondaryColor: NeonColors.cyan,
                pattern: TronPattern.grid,
                transitionDuration: const Duration(milliseconds: 850),
              );
            default:
              return MaterialPageRoute(
                builder: (_) => const LoadingScreen(),
              );
          }
        },
      ),
    );
  }
}
