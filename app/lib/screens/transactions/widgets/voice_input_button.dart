import 'package:flutter/material.dart';
import 'package:speech_to_text/speech_to_text.dart';

import '../../../core/constants/app_icons.dart';

class VoiceInputButton extends StatefulWidget {
  final ValueChanged<String> onTranscriptReady;
  final bool compact;

  const VoiceInputButton({
    super.key,
    required this.onTranscriptReady,
    this.compact = false,
  });

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
    final iconColor = _listening
        ? Colors.red
        : Theme.of(context).iconTheme.color ??
            Theme.of(context).colorScheme.onSurface;

    final icon = AppIcons.icon(
      _listening ? AppIconKey.micOff : AppIconKey.mic,
      color: iconColor,
      size: widget.compact ? 18 : 22,
    );

    if (widget.compact) {
      return Material(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        shape: const CircleBorder(),
        child: InkWell(
          customBorder: const CircleBorder(),
          onTap: _toggle,
          child: Padding(
            padding: const EdgeInsets.all(8),
            child: icon,
          ),
        ),
      );
    }

    return IconButton(
      icon: icon,
      tooltip: _listening ? 'Stop listening' : 'Speak to fill',
      onPressed: _toggle,
    );
  }
}
