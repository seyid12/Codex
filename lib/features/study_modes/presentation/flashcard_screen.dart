import 'dart:math';
import 'package:flutter/material.dart';
import '../domain/card_model.dart';
import '../../../core/utils/haptic_feedback_helper.dart';

class FlashcardScreen extends StatefulWidget {
  final CardModel card;
  final VoidCallback onNext;

  const FlashcardScreen({super.key, required this.card, required this.onNext});

  @override
  State<FlashcardScreen> createState() => _FlashcardScreenState();
}

class _FlashcardScreenState extends State<FlashcardScreen> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;
  bool _isFront = true;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: const Duration(milliseconds: 500));
    _animation = Tween<double>(begin: 0, end: 1).animate(_controller);
  }

  void _flipCard() {
    HapticHelper.light();
    if (_isFront) {
      _controller.forward();
    } else {
      _controller.reverse();
    }
    setState(() {
      _isFront = !_isFront;
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Expanded(
            child: GestureDetector(
              onTap: _flipCard,
              child: AnimatedBuilder(
                animation: _animation,
                builder: (context, child) {
                  final angle = _animation.value * pi;
                  final isUnder = angle > pi / 2;
                  return Transform(
                    transform: Matrix4.rotationY(angle)..setEntry(3, 2, 0.001),
                    alignment: Alignment.center,
                    child: isUnder
                        ? Transform(
                            transform: Matrix4.rotationY(pi),
                            alignment: Alignment.center,
                            child: _buildBack(),
                          )
                        : _buildFront(),
                  );
                },
              ),
            ),
          ),
          const SizedBox(height: 24),
          if (!_isFront) ...[
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                  onPressed: () {
                    HapticHelper.heavy();
                    // TODO: Progress Service - Mark as Wrong
                    widget.onNext();
                  },
                  child: const Text('Zordu'),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
                  onPressed: () {
                    HapticHelper.success();
                    // TODO: Progress Service - Mark as Correct
                    widget.onNext();
                  },
                  child: const Text('Kolaydı'),
                ),
              ],
            ),
          ] else ...[
            const Text('Cevabı görmek için karta dokunun', style: TextStyle(color: Colors.white54)),
          ],
        ],
      ),
    );
  }

  Widget _buildFront() {
    return Card(
      child: Center(
        padding: const EdgeInsets.all(24.0),
        child: Text(
          widget.card.question,
          textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }

  Widget _buildBack() {
    return Card(
      color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
      child: Center(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              widget.card.answer,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.greenAccent),
            ),
            if (widget.card.mnemonic.isNotEmpty) ...[
              const SizedBox(height: 32),
              const Icon(Icons.lightbulb, color: Colors.yellow, size: 32),
              const SizedBox(height: 8),
              Text(
                widget.card.mnemonic,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 18, fontStyle: FontStyle.italic, color: Colors.white70),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
