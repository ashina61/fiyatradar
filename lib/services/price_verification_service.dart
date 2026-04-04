import 'package:flutter/foundation.dart';

import '../models/price_model.dart';

class PriceVerificationSummary {
  const PriceVerificationSummary({required this.verifiedVotes, required this.wrongVotes});

  final int verifiedVotes;
  final int wrongVotes;

  int get totalVotes => verifiedVotes + wrongVotes;

  int? get approvalPercent => totalVotes == 0 ? null : ((verifiedVotes / totalVotes) * 100).round();

  String get approvalLabel => approvalPercent == null ? 'Henüz doğrulanmadı' : 'Onay %${approvalPercent!}';
}

class PriceVerificationService {
  const PriceVerificationService();

  PriceVerificationSummary summaryForPrice(PriceModel price) {
    return PriceVerificationSummary(
      verifiedVotes: price.upVotes,
      wrongVotes: price.downVotes,
    );
  }

  int? approvalPercentForPrice(PriceModel price) => summaryForPrice(price).approvalPercent;

  @visibleForTesting
  int? approvalPercent({required int verifiedVotes, required int wrongVotes}) {
    final total = verifiedVotes + wrongVotes;
    if (total == 0) return null;
    return ((verifiedVotes / total) * 100).round();
  }
}
