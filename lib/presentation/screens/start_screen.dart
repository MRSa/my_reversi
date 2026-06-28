import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../state/game_provider.dart';
import '../../domain/game_logic.dart';
import 'game_screen.dart';

class StartScreen extends ConsumerStatefulWidget {
  const StartScreen({super.key});

  @override
  ConsumerState<StartScreen> createState() => _StartScreenState();
}

class _StartScreenState extends ConsumerState<StartScreen> {
  GameMode _selectedMode = GameMode.pvc;
  StoneColor _selectedColor = StoneColor.black;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Colors.green[800]!, Colors.green[600]!],
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Title
            const Text(
              'リバーシ',
              style: TextStyle(
                fontSize: 48,
                fontWeight: FontWeight.bold,
                color: Colors.white,
                letterSpacing: 8,
                shadows: [
                  Shadow(offset: Offset(2, 2), blurRadius: 4, color: Colors.black54),
                ],
              ),
            ),
            const SizedBox(height: 48),

            // Mode Selection
            _buildSectionTitle('対戦モード'),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _buildModeChip(GameMode.pvp, '人間 vs 人間'),
                const SizedBox(width: 16),
                _buildModeChip(GameMode.pvc, '人間 vs CPU'),
              ],
            ),
            const SizedBox(height: 32),

            // Color Selection
            _buildSectionTitle('自分の色'),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _buildColorChip(StoneColor.black, '黒 (先攻)'),
                const SizedBox(width: 16),
                _buildColorChip(StoneColor.white, '白 (後攻)'),
              ],
            ),
            const SizedBox(height: 64),

            // Start Button
            ElevatedButton(
              onPressed: () {
                final notifier = ref.read(gameProvider.notifier);
                notifier.setGameMode(_selectedMode);
                notifier.setHumanColor(_selectedColor);
                notifier.resetGame(); // Initialize board and start timer

                Navigator.of(context).pushReplacement(
                  MaterialPageRoute(builder: (context) => const GameScreen()),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: Colors.green[800],
                padding: const EdgeInsets.symmetric(horizontal: 48, vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(32)),
                elevation: 8,
              ),
              child: const Text(
                'ゲーム開始',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 20,
          color: Colors.white70,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  Widget _buildModeChip(GameMode mode, String label) {
    final isSelected = _selectedMode == mode;
    return ChoiceChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (val) {
        if (val) setState(() => _selectedMode = mode);
      },
      selectedColor: Colors.white,
      backgroundColor: Colors.green[400],
      labelStyle: TextStyle(
        color: isSelected ? Colors.green[900] : Colors.white,
        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
      ),
    );
  }

  Widget _buildColorChip(StoneColor color, String label) {
    final isSelected = _selectedColor == color;
    return ChoiceChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (val) {
        if (val) setState(() => _selectedColor = color);
      },
      selectedColor: Colors.white,
      backgroundColor: Colors.green[400],
      labelStyle: TextStyle(
        color: isSelected ? Colors.green[900] : Colors.white,
        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
      ),
    );
  }
}
