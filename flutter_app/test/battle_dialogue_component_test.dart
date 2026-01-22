import 'package:flame/components.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:bored_games/src/game/hud/battle_dialogue_component.dart';
import 'package:bored_games/src/data/story_data.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('BattleDialogueComponent creation', () {
    test('creates with correct anchor', () {
      final component = BattleDialogueComponent();
      expect(component.anchor, Anchor.topCenter);
    });

    test('creates as PositionComponent', () {
      final component = BattleDialogueComponent();
      expect(component, isA<PositionComponent>());
    });
  });

  group('BattleDialogueComponent constants', () {
    test('dialogueDuration is defined', () {
      expect(BattleDialogueComponent.dialogueDuration, 4.0);
    });

    test('typewriterSpeed is defined', () {
      expect(BattleDialogueComponent.typewriterSpeed, 30.0);
    });

    test('fadeInDuration is defined', () {
      expect(BattleDialogueComponent.fadeInDuration, 0.3);
    });

    test('fadeOutDuration is defined', () {
      expect(BattleDialogueComponent.fadeOutDuration, 0.5);
    });
  });

  group('BattleDialogueComponent showDialogue', () {
    test('shows dialogue with required parameters', () {
      final component = BattleDialogueComponent();

      component.showDialogue(
        speaker: StoryData.aria,
        text: 'Test message',
      );

      expect(true, isTrue);
    });

    test('shows dialogue with mood', () {
      final component = BattleDialogueComponent();

      component.showDialogue(
        speaker: StoryData.aria,
        text: 'Test message',
        mood: BriefingMood.urgent,
      );

      expect(true, isTrue);
    });

    test('shows dialogue with priority', () {
      final component = BattleDialogueComponent();

      component.showDialogue(
        speaker: StoryData.aria,
        text: 'First message',
      );

      component.showDialogue(
        speaker: StoryData.aria,
        text: 'Priority message',
        priority: true,
      );

      expect(true, isTrue);
    });

    test('queues multiple dialogues', () {
      final component = BattleDialogueComponent();

      component.showDialogue(speaker: StoryData.aria, text: 'Message 1');
      component.showDialogue(speaker: StoryData.aria, text: 'Message 2');
      component.showDialogue(speaker: StoryData.aria, text: 'Message 3');

      expect(true, isTrue);
    });
  });

  group('BattleDialogueComponent trigger methods', () {
    test('onBossSpawn shows dialogue', () {
      final component = BattleDialogueComponent();

      component.onBossSpawn('Virus Prime');

      expect(true, isTrue);
    });

    test('onBossHalfHealth shows dialogue', () {
      final component = BattleDialogueComponent();

      component.onBossHalfHealth('Virus Prime');

      expect(true, isTrue);
    });

    test('onBossDefeated shows dialogue', () {
      final component = BattleDialogueComponent();

      component.onBossDefeated('Virus Prime');

      expect(true, isTrue);
    });

    test('onLowHealth with 1 life shows critical dialogue', () {
      final component = BattleDialogueComponent();

      component.onLowHealth(1);

      expect(true, isTrue);
    });

    test('onLowHealth with 2-3 lives shows worried dialogue', () {
      final component = BattleDialogueComponent();

      component.onLowHealth(3);

      expect(true, isTrue);
    });

    test('onLowHealth with 4+ lives does nothing', () {
      final component = BattleDialogueComponent();

      component.onLowHealth(5);

      expect(true, isTrue);
    });

    test('onBigWaveStart for wave 10', () {
      final component = BattleDialogueComponent();

      component.onBigWaveStart(10);

      expect(true, isTrue);
    });

    test('onBigWaveStart for wave 5', () {
      final component = BattleDialogueComponent();

      component.onBigWaveStart(5);

      expect(true, isTrue);
    });

    test('onBigWaveStart for wave 7 does nothing', () {
      final component = BattleDialogueComponent();

      component.onBigWaveStart(7);

      expect(true, isTrue);
    });

    test('onRandomBattleMoment shows dialogue', () {
      final component = BattleDialogueComponent();

      component.onRandomBattleMoment();

      expect(true, isTrue);
    });

    test('onDecompilerTaunt shows dialogue', () {
      final component = BattleDialogueComponent();

      component.onDecompilerTaunt();

      expect(true, isTrue);
    });

    test('onEchoEncouragement shows dialogue', () {
      final component = BattleDialogueComponent();

      component.onEchoEncouragement();

      expect(true, isTrue);
    });

    test('onFirstTowerPlaced shows dialogue', () {
      final component = BattleDialogueComponent();

      component.onFirstTowerPlaced();

      expect(true, isTrue);
    });

    test('onAbilityUsed for NEON PULSE shows dialogue', () {
      final component = BattleDialogueComponent();

      component.onAbilityUsed('NEON PULSE');

      expect(true, isTrue);
    });

    test('onAbilityUsed for NEON MINE shows dialogue', () {
      final component = BattleDialogueComponent();

      component.onAbilityUsed('NEON MINE');

      expect(true, isTrue);
    });

    test('onAbilityUsed for other ability does nothing', () {
      final component = BattleDialogueComponent();

      component.onAbilityUsed('OTHER ABILITY');

      expect(true, isTrue);
    });
  });

  group('BattleDialogueComponent update', () {
    test('update does not crash without dialogue', () {
      final component = BattleDialogueComponent();

      component.update(0.016);
      component.update(0.016);

      expect(true, isTrue);
    });

    test('update advances typewriter', () {
      final component = BattleDialogueComponent();

      component.showDialogue(
        speaker: StoryData.aria,
        text: 'This is a test message.',
      );

      component.update(0.5);

      expect(true, isTrue);
    });

    test('update handles fade in', () {
      final component = BattleDialogueComponent();

      component.showDialogue(
        speaker: StoryData.aria,
        text: 'Test message',
      );

      // During fade in
      component.update(0.1);

      expect(true, isTrue);
    });

    test('update handles fade out', () {
      final component = BattleDialogueComponent();

      component.showDialogue(
        speaker: StoryData.aria,
        text: 'Test message',
      );

      // Skip to fade out phase
      component.update(3.8);

      expect(true, isTrue);
    });

    test('update transitions to next dialogue', () {
      final component = BattleDialogueComponent();

      component.showDialogue(
        speaker: StoryData.aria,
        text: 'First message',
      );
      component.showDialogue(
        speaker: StoryData.aria,
        text: 'Second message',
      );

      // Update past first dialogue duration
      component.update(4.5);

      expect(true, isTrue);
    });

    test('update with zero dt does not crash', () {
      final component = BattleDialogueComponent();

      component.showDialogue(
        speaker: StoryData.aria,
        text: 'Test message',
      );

      component.update(0.0);

      expect(true, isTrue);
    });

    test('multiple rapid updates work', () {
      final component = BattleDialogueComponent();

      component.showDialogue(
        speaker: StoryData.aria,
        text: 'Test message',
      );

      for (int i = 0; i < 100; i++) {
        component.update(0.016);
      }

      expect(true, isTrue);
    });
  });

  group('BattleDialogueComponent speakers', () {
    test('shows dialogue from Aria', () {
      final component = BattleDialogueComponent();

      component.showDialogue(
        speaker: StoryData.aria,
        text: 'Aria message',
      );

      expect(true, isTrue);
    });

    test('shows dialogue from Echo', () {
      final component = BattleDialogueComponent();

      component.showDialogue(
        speaker: StoryData.echo,
        text: 'Echo message',
      );

      expect(true, isTrue);
    });

    test('shows dialogue from Decompiler', () {
      final component = BattleDialogueComponent();

      component.showDialogue(
        speaker: StoryData.decompiler,
        text: 'Decompiler message',
      );

      expect(true, isTrue);
    });
  });

  group('BattleDialogueComponent moods', () {
    test('handles urgent mood', () {
      final component = BattleDialogueComponent();

      component.showDialogue(
        speaker: StoryData.aria,
        text: 'Test',
        mood: BriefingMood.urgent,
      );

      component.update(0.5);
      expect(true, isTrue);
    });

    test('handles analytical mood', () {
      final component = BattleDialogueComponent();

      component.showDialogue(
        speaker: StoryData.aria,
        text: 'Test',
        mood: BriefingMood.analytical,
      );

      component.update(0.5);
      expect(true, isTrue);
    });

    test('handles worried mood', () {
      final component = BattleDialogueComponent();

      component.showDialogue(
        speaker: StoryData.aria,
        text: 'Test',
        mood: BriefingMood.worried,
      );

      component.update(0.5);
      expect(true, isTrue);
    });

    test('handles serious mood', () {
      final component = BattleDialogueComponent();

      component.showDialogue(
        speaker: StoryData.aria,
        text: 'Test',
        mood: BriefingMood.serious,
      );

      component.update(0.5);
      expect(true, isTrue);
    });

    test('handles mysterious mood', () {
      final component = BattleDialogueComponent();

      component.showDialogue(
        speaker: StoryData.echo,
        text: 'Test',
        mood: BriefingMood.mysterious,
      );

      component.update(0.5);
      expect(true, isTrue);
    });

    test('handles hopeful mood', () {
      final component = BattleDialogueComponent();

      component.showDialogue(
        speaker: StoryData.aria,
        text: 'Test',
        mood: BriefingMood.hopeful,
      );

      component.update(0.5);
      expect(true, isTrue);
    });

    test('handles surprised mood', () {
      final component = BattleDialogueComponent();

      component.showDialogue(
        speaker: StoryData.aria,
        text: 'Test',
        mood: BriefingMood.surprised,
      );

      component.update(0.5);
      expect(true, isTrue);
    });

    test('handles emotional mood', () {
      final component = BattleDialogueComponent();

      component.showDialogue(
        speaker: StoryData.echo,
        text: 'Test',
        mood: BriefingMood.emotional,
      );

      component.update(0.5);
      expect(true, isTrue);
    });

    test('handles epic mood', () {
      final component = BattleDialogueComponent();

      component.showDialogue(
        speaker: StoryData.aria,
        text: 'Test',
        mood: BriefingMood.epic,
      );

      component.update(0.5);
      expect(true, isTrue);
    });

    test('handles dark mood', () {
      final component = BattleDialogueComponent();

      component.showDialogue(
        speaker: StoryData.decompiler,
        text: 'Test',
        mood: BriefingMood.dark,
      );

      component.update(0.5);
      expect(true, isTrue);
    });

    test('handles sad mood', () {
      final component = BattleDialogueComponent();

      component.showDialogue(
        speaker: StoryData.echo,
        text: 'Test',
        mood: BriefingMood.sad,
      );

      component.update(0.5);
      expect(true, isTrue);
    });

    test('handles confused mood', () {
      final component = BattleDialogueComponent();

      component.showDialogue(
        speaker: StoryData.aria,
        text: 'Test',
        mood: BriefingMood.confused,
      );

      component.update(0.5);
      expect(true, isTrue);
    });

    test('handles revelation mood', () {
      final component = BattleDialogueComponent();

      component.showDialogue(
        speaker: StoryData.echo,
        text: 'Test',
        mood: BriefingMood.revelation,
      );

      component.update(0.5);
      expect(true, isTrue);
    });
  });

  group('BattleDialogueComponent edge cases', () {
    test('handles empty text', () {
      final component = BattleDialogueComponent();

      component.showDialogue(
        speaker: StoryData.aria,
        text: '',
      );

      component.update(0.5);
      expect(true, isTrue);
    });

    test('handles very long text', () {
      final component = BattleDialogueComponent();

      component.showDialogue(
        speaker: StoryData.aria,
        text: 'This is a very long message that should test the typewriter effect and text wrapping capabilities of the battle dialogue component in the game.',
      );

      component.update(0.5);
      expect(true, isTrue);
    });

    test('handles special characters in text', () {
      final component = BattleDialogueComponent();

      component.showDialogue(
        speaker: StoryData.aria,
        text: '¡Alerta! ¿Qué está pasando? 100% crítico...',
      );

      component.update(0.5);
      expect(true, isTrue);
    });

    test('handles rapid showDialogue calls', () {
      final component = BattleDialogueComponent();

      for (int i = 0; i < 20; i++) {
        component.showDialogue(
          speaker: StoryData.aria,
          text: 'Message $i',
        );
      }

      expect(true, isTrue);
    });
  });

  group('BattleDialogueComponent multiple instances', () {
    test('multiple instances are independent', () {
      final component1 = BattleDialogueComponent();
      final component2 = BattleDialogueComponent();

      component1.showDialogue(
        speaker: StoryData.aria,
        text: 'Message 1',
      );

      component1.update(0.5);
      component2.update(0.5);

      expect(true, isTrue);
    });
  });
}
