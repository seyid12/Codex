import 'dart:async';
import 'package:flutter/material.dart';
import '../domain/card_model.dart';
import '../../../core/utils/shake_animation_wrapper.dart';
import '../../../core/utils/haptic_feedback_helper.dart';

class QuizScreen extends StatefulWidget {
  final CardModel card;
  final VoidCallback onNext;

  const QuizScreen({super.key, required this.card, required this.onNext});

  @override
  State<QuizScreen> createState() => _QuizScreenState();
}

class _QuizScreenState extends State<QuizScreen> {
  int _timeLeft = 10;
  Timer? _timer;
  bool _shake = false;
  int? _selectedOptionIndex;
  bool _answered = false;

  @override
  void initState() {
    super.initState();
    _startTimer();
  }

  void _startTimer() {
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_timeLeft > 0) {
        setState(() => _timeLeft--);
      } else {
        _timer?.cancel();
        _handleTimeOut();
      }
    });
  }

  void _handleTimeOut() {
    if (!_answered) {
      HapticHelper.error();
      setState(() {
        _shake = true;
        _answered = true;
      });
      Future.delayed(const Duration(seconds: 2), widget.onNext);
    }
  }

  void _handleOptionSelect(int index) {
    if (_answered) return;

    _timer?.cancel();
    setState(() {
      _selectedOptionIndex = index;
      _answered = true;
    });

    if (index == widget.card.correctOptionIndex) {
      HapticHelper.success();
      Future.delayed(const Duration(seconds: 1), widget.onNext);
    } else {
      HapticHelper.error();
      setState(() => _shake = true);
      Future.delayed(const Duration(seconds: 2), widget.onNext);
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ShakeWrapper(
      shake: _shake,
      onShakeCompleted: () => setState(() => _shake = false),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            // Time Bar
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: LinearProgressIndicator(
                value: _timeLeft / 10,
                minHeight: 12,
                backgroundColor: Colors.white24,
                valueColor: AlwaysStoppedAnimation<Color>(
                  _timeLeft > 3 ? Theme.of(context).colorScheme.secondary : Colors.redAccent,
                ),
              ),
            ),
            const SizedBox(height: 24),
            Text(
              widget.card.question,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            const Spacer(),
            ...List.generate(widget.card.options.length, (index) {
              Color buttonColor = Theme.of(context).colorScheme.surface;
              if (_answered) {
                if (index == widget.card.correctOptionIndex) {
                  buttonColor = Colors.green; // Correct answer
                } else if (index == _selectedOptionIndex) {
                  buttonColor = Colors.red; // Selected wrong answer
                }
              }

              return Padding(
                padding: const EdgeInsets.only(bottom: 12.0),
                child: SizedBox(
                  width: double.infinity,
                  height: 60,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: buttonColor,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      side: BorderSide(color: Theme.of(context).colorScheme.secondary.withOpacity(0.5)),
                    ),
                    onPressed: () => _handleOptionSelect(index),
                    child: Text(
                      widget.card.options[index],
                      style: const TextStyle(fontSize: 16),
                    ),
                  ),
                ),
              );
            }),
            const Spacer(),
          ],
        ),
      ),
    );
  }
}
