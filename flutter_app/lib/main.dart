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
              return MaterialPageRoute(
                builder: (_) => const MainMenuScreen(),
              );
            case '/levels':
              return MaterialPageRoute(
                builder: (_) => const LevelSelectScreen(),
              );
            case '/game':
              final levelId = settings.arguments as int? ?? 1;
              return MaterialPageRoute(
                builder: (_) => GameScreen(levelId: levelId),
              );
            case '/story':
              return MaterialPageRoute(
                builder: (_) => const StoryScreen(),
              );
            case '/settings':
              return MaterialPageRoute(
                builder: (_) => const SettingsScreen(),
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
