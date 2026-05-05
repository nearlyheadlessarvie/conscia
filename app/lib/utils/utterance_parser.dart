class ParseResult {
  final String description;
  final double? amount;
  final String? category;

  const ParseResult({
    required this.description,
    this.amount,
    this.category,
  });
}

class UtteranceParser {
  static const _numberWords = <String, double>{
    'zero': 0, 'one': 1, 'two': 2, 'three': 3, 'four': 4,
    'five': 5, 'six': 6, 'seven': 7, 'eight': 8, 'nine': 9,
    'ten': 10, 'eleven': 11, 'twelve': 12, 'thirteen': 13,
    'fourteen': 14, 'fifteen': 15, 'sixteen': 16, 'seventeen': 17,
    'eighteen': 18, 'nineteen': 19, 'twenty': 20, 'thirty': 30,
    'forty': 40, 'fifty': 50, 'sixty': 60, 'seventy': 70,
    'eighty': 80, 'ninety': 90, 'hundred': 100,
  };

  static const _centWords = <String, double>{
    'fifty': 0.50, 'twenty-five': 0.25, 'seventy-five': 0.75,
    'ten': 0.10, 'twenty': 0.20, 'thirty': 0.30, 'forty': 0.40,
    'sixty': 0.60, 'seventy': 0.70, 'eighty': 0.80, 'ninety': 0.90,
  };

  static const _categoryKeywords = <String, List<String>>{
    'Coffee': ['coffee', 'latte', 'espresso', 'cappuccino', 'starbucks', 'cafe', 'café', 'barista'],
    'Dining': ['lunch', 'dinner', 'breakfast', 'restaurant', 'jollibee', 'mcdo', 'mcdonald', 'food', 'meal', 'eat', 'dine', 'dining', 'fastfood', 'kfc', 'burger', 'pizza'],
    'Shopping': ['shopping', 'shopee', 'lazada', 'amazon', 'mall', 'grocery', 'groceries', 'supermarket', 'store', 'bought', 'purchase'],
    'Gaming': ['gaming', 'game', 'steam', 'playstation', 'xbox', 'nintendo'],
    'Travel': ['travel', 'flight', 'airline', 'hotel', 'airbnb', 'booking', 'trip', 'vacation'],
    'Transport': ['uber', 'grab', 'taxi', 'bus', 'train', 'commute', 'transport', 'gas', 'fuel', 'toll'],
    'Entertainment': ['netflix', 'spotify', 'movie', 'cinema', 'concert', 'subscription', 'streaming'],
    'Health': ['pharmacy', 'medicine', 'doctor', 'hospital', 'clinic', 'gym', 'vitamins'],
    'Utilities': ['electricity', 'water', 'internet', 'wifi', 'phone', 'bill', 'utility'],
  };

  static ParseResult parse(String transcript) {
    if (transcript.isEmpty) {
      return const ParseResult(description: '');
    }

    final tokens = transcript.toLowerCase().split(RegExp(r'\s+'));
    final usedIndices = <int>{};

    // --- Extract amount ---
    double? amount;

    // Try regex first: $5.50 or 5.50 or 5
    final numericRegex = RegExp(r'\$?(\d+(?:\.\d{1,2})?)');
    final numericMatch = numericRegex.firstMatch(transcript);
    if (numericMatch != null) {
      amount = double.tryParse(numericMatch.group(1)!);
      // Find which token index contains this match
      for (int i = 0; i < tokens.length; i++) {
        final cleaned = tokens[i].replaceAll(RegExp(r'[^\d.]'), '');
        if (cleaned == numericMatch.group(1)) {
          usedIndices.add(i);
          break;
        }
      }
    }

    // Try spoken number if no numeric found
    if (amount == null) {
      for (int i = 0; i < tokens.length; i++) {
        final word = tokens[i].replaceAll(RegExp(r'[^a-z]'), '');
        final wholeValue = _numberWords[word];
        if (wholeValue != null) {
          double cents = 0;
          if (i + 1 < tokens.length) {
            final nextWord = tokens[i + 1].replaceAll(RegExp(r'[^a-z]'), '');
            final centValue = _centWords[nextWord];
            if (centValue != null && wholeValue < 100) {
              cents = centValue;
              usedIndices.add(i + 1);
            }
          }
          amount = wholeValue + cents;
          usedIndices.add(i);
          break;
        }
      }
    }

    // --- Extract category ---
    String? category;
    final lowerTranscript = transcript.toLowerCase();
    outer:
    for (final entry in _categoryKeywords.entries) {
      for (final keyword in entry.value) {
        if (lowerTranscript.contains(keyword)) {
          category = entry.key;
          break outer;
        }
      }
    }

    // --- Build description ---
    final descTokens = <String>[];
    for (int i = 0; i < tokens.length; i++) {
      if (!usedIndices.contains(i)) descTokens.add(tokens[i]);
    }
    final description = descTokens.join(' ').trim();

    return ParseResult(
      description: description.isEmpty ? transcript : description,
      amount: amount,
      category: category,
    );
  }
}
