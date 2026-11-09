import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../core_services.dart';
import '../iap/product_spec.dart';
import '../iap/purchase_service.dart';
import '../l10n/core_localizations.dart';

/// Ready-made store page: wallet balances, products with localized prices,
/// and the "Restore purchases" button Apple requires. Texts follow the
/// player's language ([CoreLocalizations]).
class StoreScreen extends StatelessWidget {
  const StoreScreen({super.key, this.title});

  /// AppBar title; defaults to "Store" in the player's language.
  final String? title;

  @override
  Widget build(BuildContext context) {
    final core = CoreServices.of(context);
    final purchases = core.purchases;
    final entitlements = core.entitlements;
    final l10n = CoreLocalizations.of(context);
    final locale = Localizations.localeOf(context).toString();

    return Scaffold(
      appBar: AppBar(title: Text(title ?? l10n.storeTitle)),
      body: ListenableBuilder(
        listenable: Listenable.merge([purchases, entitlements]),
        builder: (context, child) {
          if (!purchases.isReady) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!purchases.isAvailable) {
            return _StoreUnavailable(onRetry: purchases.init);
          }
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              if (purchases.isFake)
                _Banner(
                  icon: Icons.science_outlined,
                  message: l10n.storeTestBanner,
                ),
              if (purchases.errorKind case final kind?)
                _Banner(
                  icon: Icons.error_outline,
                  message: switch (kind) {
                    PurchaseErrorKind.unavailable => l10n.errorUnavailable,
                    PurchaseErrorKind.failed => l10n.errorFailed,
                  },
                  onDismiss: purchases.clearError,
                  dismissLabel: l10n.dismiss,
                ),
              for (final entry in entitlements.wallet.entries)
                ListTile(
                  leading: const Icon(Icons.savings_outlined),
                  title: Text(
                    core.config.walletName?.call(context, entry.key) ??
                        _capitalize(entry.key),
                  ),
                  trailing: Text(
                    NumberFormat.decimalPattern(locale).format(entry.value),
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ),
              for (final item in purchases.items)
                _ProductTile(
                  item: item,
                  text: item.fromStore
                      ? null
                      : core.config.productText?.call(context, item.spec),
                  owned:
                      item.spec.kind == ProductKind.nonConsumable &&
                      entitlements.owns(item.spec.id),
                  pending: purchases.pending.contains(item.spec.id),
                  onBuy: () {
                    purchases.buy(item.spec.id);
                  },
                ),
              if (purchases.items.isEmpty)
                Padding(
                  padding: const EdgeInsets.all(24),
                  child: Text(l10n.storeEmpty, textAlign: TextAlign.center),
                ),
              const SizedBox(height: 24),
              Center(
                child: TextButton(
                  onPressed: purchases.restore,
                  child: Text(l10n.restorePurchases),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  static String _capitalize(String s) =>
      s.isEmpty ? s : s[0].toUpperCase() + s.substring(1);
}

class _ProductTile extends StatelessWidget {
  const _ProductTile({
    required this.item,
    this.text,
    required this.owned,
    required this.pending,
    required this.onBuy,
  });

  final StoreItem item;

  /// Translated title and description when the item isn't from the store.
  final ProductText? text;
  final bool owned;
  final bool pending;
  final VoidCallback onBuy;

  @override
  Widget build(BuildContext context) {
    final Widget trailing;
    if (owned) {
      trailing = Icon(
        Icons.check_circle,
        color: Theme.of(context).colorScheme.primary,
      );
    } else if (pending) {
      trailing = const SizedBox.square(
        dimension: 24,
        child: CircularProgressIndicator(strokeWidth: 2),
      );
    } else {
      trailing = FilledButton(onPressed: onBuy, child: Text(item.price));
    }

    final title = text?.title ?? item.title;
    final description = text?.description ?? item.description;
    return Card(
      child: ListTile(
        title: Text(title),
        subtitle: description.isEmpty ? null : Text(description),
        trailing: trailing,
      ),
    );
  }
}

class _StoreUnavailable extends StatelessWidget {
  const _StoreUnavailable({required this.onRetry});

  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final l10n = CoreLocalizations.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.cloud_off_outlined, size: 48),
            const SizedBox(height: 16),
            Text(l10n.storeUnavailable, textAlign: TextAlign.center),
            const SizedBox(height: 16),
            OutlinedButton(onPressed: onRetry, child: Text(l10n.tryAgain)),
          ],
        ),
      ),
    );
  }
}

class _Banner extends StatelessWidget {
  const _Banner({
    required this.icon,
    required this.message,
    this.onDismiss,
    this.dismissLabel,
  });

  final IconData icon;
  final String message;
  final VoidCallback? onDismiss;
  final String? dismissLabel;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Card(
      color: colors.secondaryContainer,
      child: ListTile(
        leading: Icon(icon, color: colors.onSecondaryContainer),
        title: Text(
          message,
          style: TextStyle(color: colors.onSecondaryContainer),
        ),
        trailing: onDismiss == null
            ? null
            : IconButton(
                icon: const Icon(Icons.close),
                tooltip: dismissLabel,
                onPressed: onDismiss,
              ),
      ),
    );
  }
}
