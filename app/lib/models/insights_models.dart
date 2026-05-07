class InsightsSummary {
  final double regrettedAmount;
  final String regrettedCategory;
  final double avgRegretRate;
  final int patternCount;
  final DateTime updatedAt;

  const InsightsSummary({
    required this.regrettedAmount,
    required this.regrettedCategory,
    required this.avgRegretRate,
    required this.patternCount,
    required this.updatedAt,
  });

  factory InsightsSummary.fromJson(Map<String, dynamic> json) => InsightsSummary(
        regrettedAmount: (json['regrettedAmount'] as num).toDouble(),
        regrettedCategory: json['regrettedCategory'] as String,
        avgRegretRate: (json['avgRegretRate'] as num).toDouble(),
        patternCount: json['patternCount'] as int,
        updatedAt: DateTime.parse(json['updatedAt'] as String),
      );
}

class CategoryStat {
  final String category;
  final double totalSpend;
  final double regrettedSpend;
  final double regretRate;
  final int transactionCount;
  final double projectedAnnual;

  const CategoryStat({
    required this.category,
    required this.totalSpend,
    required this.regrettedSpend,
    required this.regretRate,
    required this.transactionCount,
    required this.projectedAnnual,
  });

  factory CategoryStat.fromJson(Map<String, dynamic> json) => CategoryStat(
        category: json['category'] as String,
        totalSpend: (json['totalSpend'] as num).toDouble(),
        regrettedSpend: (json['regrettedSpend'] as num).toDouble(),
        regretRate: (json['regretRate'] as num).toDouble(),
        transactionCount: json['transactionCount'] as int,
        projectedAnnual: (json['projectedAnnual'] as num).toDouble(),
      );
}

class MerchantStat {
  final String merchant;
  final int visitCount;
  final int regretCount;
  final double regretRate;
  final String lastVisitDate;

  const MerchantStat({
    required this.merchant,
    required this.visitCount,
    required this.regretCount,
    required this.regretRate,
    required this.lastVisitDate,
  });

  factory MerchantStat.fromJson(Map<String, dynamic> json) => MerchantStat(
        merchant: json['merchant'] as String,
        visitCount: json['visitCount'] as int,
        regretCount: json['regretCount'] as int,
        regretRate: (json['regretRate'] as num).toDouble(),
        lastVisitDate: json['lastVisitDate'] as String,
      );
}

class TransactionSummary {
  final String id;
  final double amount;
  final String currencyCode;
  final String category;
  final String? merchant;
  final DateTime date;
  final String? regretLevel;

  const TransactionSummary({
    required this.id,
    required this.amount,
    required this.currencyCode,
    required this.category,
    this.merchant,
    required this.date,
    this.regretLevel,
  });

  factory TransactionSummary.fromJson(Map<String, dynamic> json) => TransactionSummary(
        id: json['id'] as String,
        amount: (json['amount'] as num).toDouble(),
        currencyCode: json['currencyCode'] as String,
        category: json['category'] as String,
        merchant: json['merchant'] as String?,
        date: DateTime.parse(json['date'] as String),
        regretLevel: json['regretLevel'] as String?,
      );
}

class CategoryDetail {
  final CategoryStat stats;
  final List<TransactionSummary> recentTransactions;

  const CategoryDetail({required this.stats, required this.recentTransactions});

  factory CategoryDetail.fromJson(Map<String, dynamic> json) => CategoryDetail(
        stats: CategoryStat.fromJson(json['stats'] as Map<String, dynamic>),
        recentTransactions: (json['recentTransactions'] as List)
            .map((e) => TransactionSummary.fromJson(e as Map<String, dynamic>))
            .toList(),
      );
}

class MerchantDetail {
  final MerchantStat stats;
  final List<TransactionSummary> recentTransactions;

  const MerchantDetail({required this.stats, required this.recentTransactions});

  factory MerchantDetail.fromJson(Map<String, dynamic> json) => MerchantDetail(
        stats: MerchantStat.fromJson(json['stats'] as Map<String, dynamic>),
        recentTransactions: (json['recentTransactions'] as List)
            .map((e) => TransactionSummary.fromJson(e as Map<String, dynamic>))
            .toList(),
      );
}
