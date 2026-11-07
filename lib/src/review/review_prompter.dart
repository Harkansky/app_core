import 'package:flutter/foundation.dart';
import 'package:in_app_review/in_app_review.dart';

import '../storage/key_value_store.dart';

/// Asks the OS for its native "rate this app" prompt once, after the player
/// has had [threshold] good moments (a high score, a finished level...).
///
/// The OS decides whether the prompt actually shows; Apple caps it at three
/// times a year, so asking at a happy moment matters more than asking often.
class ReviewPrompter {
  ReviewPrompter(this._store, {required this.threshold});

  static const _countKey = 'core.review.count';
  static const _doneKey = 'core.review.done';

  final KeyValueStore _store;
  final int threshold;

  int get positiveEvents => _store.getInt(_countKey) ?? 0;
  bool get hasAsked => _store.getBool(_doneKey) ?? false;

  Future<void> recordPositiveEvent() async {
    if (threshold <= 0 || hasAsked) return;
    final count = positiveEvents + 1;
    await _store.setInt(_countKey, count);
    if (count < threshold) return;

    await _store.setBool(_doneKey, true);
    try {
      final review = InAppReview.instance;
      if (await review.isAvailable()) await review.requestReview();
    } catch (error) {
      debugPrint('[app_core] Review prompt failed: $error');
    }
  }

  /// Opens the store page (for an explicit "Rate us" button).
  /// [appStoreId] is the numeric Apple ID, needed on iOS only.
  Future<void> openStoreListing({String? appStoreId}) =>
      InAppReview.instance.openStoreListing(appStoreId: appStoreId);
}
