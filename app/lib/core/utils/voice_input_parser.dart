class VoiceInputParseResult {
  const VoiceInputParseResult({
    required this.transcript,
    this.amount,
    this.category,
    this.counterparty,
  });

  final String transcript;
  final double? amount;
  final String? category;
  final String? counterparty;
}

class VoiceInputParser {
  VoiceInputParser._();

  static VoiceInputParseResult parse(
    String transcript, {
    required List<String> categories,
  }) {
    final normalized = transcript.trim();
    if (normalized.isEmpty) {
      return const VoiceInputParseResult(transcript: '');
    }

    final lower = normalized.toLowerCase();
    String? detectedCategory;
    for (final category in categories) {
      if (lower.contains(category.toLowerCase())) {
        detectedCategory = category;
        break;
      }
    }

    final amount = _extractAmount(lower);
    var remainder = normalized;

    if (detectedCategory != null) {
      remainder = remainder.replaceAll(
        RegExp(detectedCategory, caseSensitive: false),
        '',
      );
    }

    remainder = remainder.replaceAll(
      RegExp(r'\b\d[\d,]*(?:\.\d+)?\b'),
      '',
    );
    remainder = remainder.replaceAll(
      RegExp(
        r'\b(zero|one|two|three|four|five|six|seven|eight|nine|ten|eleven|twelve|thirteen|fourteen|fifteen|sixteen|seventeen|eighteen|nineteen|twenty|thirty|forty|fifty|sixty|seventy|eighty|ninety|hundred|thousand|million|and|peso|pesos|php|dollar|dollars|usd)\b',
        caseSensitive: false,
      ),
      '',
    );
    remainder = remainder.replaceAll(
      RegExp(
        r'\b(spent|pay|paid|bought|buy|purchase|purchased|for|at|from|on|expense|income)\b',
        caseSensitive: false,
      ),
      '',
    );
    remainder = remainder.replaceAll(RegExp(r'\s+'), ' ').trim();

    return VoiceInputParseResult(
      transcript: normalized,
      amount: amount,
      category: detectedCategory,
      counterparty: remainder.isEmpty ? null : remainder,
    );
  }

  static double? _extractAmount(String input) {
    final numericMatch = RegExp(r'\b\d[\d,]*(?:\.\d+)?\b').firstMatch(input);
    if (numericMatch != null) {
      final cleaned = numericMatch.group(0)!.replaceAll(',', '');
      return double.tryParse(cleaned);
    }

    final words = input
        .replaceAll('-', ' ')
        .split(RegExp(r'\s+'))
        .where((word) => word.isNotEmpty)
        .toList();
    if (words.isEmpty) return null;

    const units = {
      'zero': 0,
      'one': 1,
      'two': 2,
      'three': 3,
      'four': 4,
      'five': 5,
      'six': 6,
      'seven': 7,
      'eight': 8,
      'nine': 9,
      'ten': 10,
      'eleven': 11,
      'twelve': 12,
      'thirteen': 13,
      'fourteen': 14,
      'fifteen': 15,
      'sixteen': 16,
      'seventeen': 17,
      'eighteen': 18,
      'nineteen': 19,
    };
    const tens = {
      'twenty': 20,
      'thirty': 30,
      'forty': 40,
      'fifty': 50,
      'sixty': 60,
      'seventy': 70,
      'eighty': 80,
      'ninety': 90,
    };

    var total = 0;
    var current = 0;
    var usedNumberWord = false;

    for (final word in words) {
      if (units.containsKey(word)) {
        current += units[word]!;
        usedNumberWord = true;
      } else if (tens.containsKey(word)) {
        current += tens[word]!;
        usedNumberWord = true;
      } else if (word == 'hundred') {
        current = (current == 0 ? 1 : current) * 100;
        usedNumberWord = true;
      } else if (word == 'thousand') {
        total += (current == 0 ? 1 : current) * 1000;
        current = 0;
        usedNumberWord = true;
      } else if (word == 'million') {
        total += (current == 0 ? 1 : current) * 1000000;
        current = 0;
        usedNumberWord = true;
      }
    }

    if (!usedNumberWord) return null;
    return (total + current).toDouble();
  }
}
