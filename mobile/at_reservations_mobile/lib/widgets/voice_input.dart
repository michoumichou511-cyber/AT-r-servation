import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:speech_to_text/speech_to_text.dart';
import '../config/theme.dart';
import '../utils/haptics.dart';

class VoiceInputButton extends StatefulWidget {
  final ValueChanged<String> onResult;
  final String locale;

  const VoiceInputButton({
    super.key,
    required this.onResult,
    this.locale = 'fr-FR',
  });

  @override
  State<VoiceInputButton> createState() => _VoiceInputButtonState();
}

class _VoiceInputButtonState extends State<VoiceInputButton>
    with SingleTickerProviderStateMixin {
  final _speech = SpeechToText();
  bool _listening = false;
  bool _available = false;
  String _currentText = '';
  late AnimationController _pulseCtrl;

  @override
  void initState() {
    super.initState();
    _pulseCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );
    _initSpeech();
  }

  Future<void> _initSpeech() async {
    _available = await _speech.initialize();
    if (mounted) setState(() {});
  }

  Future<void> _startListening() async {
    if (!_available) return;
    Haptics.impact();
    setState(() {
      _listening = true;
      _currentText = '';
    });
    _pulseCtrl.repeat(reverse: true);

    await _speech.listen(
      onResult: (result) {
        setState(() => _currentText = result.recognizedWords);
        if (result.finalResult) {
          _stopListening();
        }
      },
      listenOptions: SpeechListenOptions(
        localeId: widget.locale,
        listenFor: const Duration(seconds: 30),
        pauseFor: const Duration(seconds: 3),
        listenMode: ListenMode.dictation,
        cancelOnError: true,
        autoPunctuation: true,
        partialResults: true,
      ),
    );
  }

  void _stopListening() {
    _speech.stop();
    _pulseCtrl.stop();
    _pulseCtrl.reset();
    if (_currentText.isNotEmpty) {
      widget.onResult(_currentText);
      Haptics.success();
    }
    if (mounted) {
      setState(() => _listening = false);
    }
  }

  @override
  void dispose() {
    _speech.stop();
    _pulseCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!_available) return const SizedBox.shrink();

    if (_listening) {
      return _buildListeningUI();
    }

    return IconButton(
      onPressed: _startListening,
      icon: const Icon(Icons.mic, color: DS.primary),
      tooltip: 'Dictée vocale',
    );
  }

  Widget _buildListeningUI() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: DS.primary.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: DS.primary.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          AnimatedBuilder(
            animation: _pulseCtrl,
            builder: (context, child) {
              final scale = 1.0 + _pulseCtrl.value * 0.3;
              return Transform.scale(
                scale: scale,
                child: Container(
                  width: 12,
                  height: 12,
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    color: DS.error,
                  ),
                ),
              );
            },
          ),
          const SizedBox(width: 8),
          if (_currentText.isNotEmpty)
            Flexible(
              child: Text(
                _currentText,
                style: TextStyle(fontSize: 13, color: context.textPrimary),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            )
          else
            Text(
              'Parlez...',
              style: TextStyle(
                fontSize: 13,
                color: context.textMuted,
                fontStyle: FontStyle.italic,
              ),
            )
                .animate(onPlay: (c) => c.repeat(reverse: true))
                .fadeIn(duration: 800.ms),
          const SizedBox(width: 8),
          GestureDetector(
            onTap: _stopListening,
            child: Container(
              padding: const EdgeInsets.all(4),
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                color: DS.error,
              ),
              child: const Icon(Icons.stop, size: 16, color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }
}
