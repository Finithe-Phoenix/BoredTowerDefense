import 'package:flame/game.dart';
import 'package:flutter/widgets.dart';

import 'src/game/bored_games_game.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final game = BoredGamesGame();
  runApp(GameWidget(game: game));
}
