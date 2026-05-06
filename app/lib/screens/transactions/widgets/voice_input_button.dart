import 'package:flutter/material.dart';
import 'package:speech_to_text/speech_to_text.dart';

class VoiceInputButton extends StatefulWidget {
  final ValueChanged<String> onTranscriptReady;

  const VoiceInputButton({super.key, required this.onTranscriptReady});

  @override
  State<VoiceInputButton> createState() => _VoiceInputButtonState();
}

class _VoiceInputButtonState extends State<VoiceInputButton> {
  final _speech = SpeechToText();
  bool _available = false;
  bool _listening = false;

  @override
  void initState() {
    super.initState();
    _speech.initialize().then((available) {
      if (mounted) setState(() => _available = available);
    });
  }

  Future<void> _toggle() async {
    if (_listening) {
      await _speech.stop();
      setState(() => _listening = false);
      return;
    }

    setState(() => _listening = true);
    await _speech.listen(
      onResult: (result) {
        if (result.finalResult) {
          setState(() => _listening = false);
          widget.onTranscriptReady(result.recognizedWords);
        }
      },
      listenFor: const Duration(seconds: 30),
      pauseFor: const Duration(seconds: 3),
    );
  }

  @override
  void dispose() {
    _speech.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!_available) return const SizedBox.shrink();

    return IconButton(
      icon: Icon(
        _listening ? Icons.stop_circle_outlined : Icons.mic_outlined,
        color: _listening ? Colors.red : null,
      ),
      tooltip: _listening ? 'Stop listening' : 'Speak to fill',
      onPressed: _toggle,
    );
  }
}
