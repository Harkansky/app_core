import 'package:flutter/material.dart';

import '../core_services.dart';
import '../iap/product_spec.dart';

/// Ready-made store page: wallet balances, products with localized prices,
/// and the "Restore purchases" button Apple requires.
class StoreScreen extends StatelessWidget {
  const StoreScreen({super.key, this.title = 'Store'});

  final String title;

  @override
  Widget build(BuildContext context) {
    final core = CoreServices.of(context);
    final purchases = core.purchases;
    final entitlements = core.entitlements;

    return Scaffold(
      appBar: AppBar(title: Text(title)),
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
              if (purchases.isFake) const _Banner(
                icon: Icons.science_outlined,
                message: 'Test store: purchases are free and only saved on this device.',
              ),
              if (purchases.lastError case final error?)
                _Banner(
                  icon: Icons.error_outline,
                  message: error,
                  onDismiss: purchases.clearError,
                ),
              for (final entry in entitlements.wallet.entries)
                ListTile(
                  leading: const Icon(Icons.savings_outlined),
                  title: Text(_capitalize(entry.key)),
                  trailing: Text(
                    '${entry.value}',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ),
              for (final item in purchases.items)
                _ProductTile(
                  item: item,
                  owned: item.spec.kind == ProductKind.nonConsumable &&
                      entitlements.owns(item.spec.id),
                  pending: purchases.pending.contains(item.spec.id),
                  onBuy: () {
                    purchases.buy(item.spec.id);
                  },
                ),
              if (purchases.items.isEmpty)
                const Padding(
                  padding: EdgeInsets.all(24),
                  child: Text('Nothing for sale yet.', textAlign: TextAlign.center),
                ),
              const SizedBox(height: 24),
              Center(
                child: TextButton(
                  onPressed: purchases.restore,
                  child: const Text('Restore purchases'),
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
    required this.owned,
    required this.pending,
    required this.onBuy,
  });

  final StoreItem item;
  final bool owned;
  final bool pending;
  final VoidCallback onBuy;

  @override
  Widget build(BuildContext context) {
    final Widget trailing;
    if (owned) {
      trailing = Icon(Icons.check_circle, color: Theme.of(context).colorScheme.primary);
    } else if (pending) {
      trailing = const SizedBox.square(
        dimension: 24,
        child: CircularProgressIndicator(strokeWidth: 2),
      );
    } else {
      trailing = FilledButton(onPressed: onBuy, child: Text(item.price));
    }

    return Card(
      child: ListTile(
        title: Text(item.title),
        subtitle: item.description.isEmpty ? null : Text(item.description),
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
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.cloud_off_outlined, size: 48),
            const SizedBox(height: 16),
            const Text(
              'The store is unavailable right now. Everything you already own keeps working offline.',
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            OutlinedButton(onPressed: onRetry, child: const Text('Try again')),
          ],
        ),
      ),
    );
  }
}

class _Banner extends StatelessWidget {
  const _Banner({required this.icon, required this.message, this.onDismiss});

  final IconData icon;
  final String message;
  final VoidCallback? onDismiss;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Card(
      color: colors.secondaryContainer,
      child: ListTile(
        leading: Icon(icon, color: colors.onSecondaryContainer),
        title: Text(message, style: TextStyle(color: colors.onSecondaryContainer)),
        trailing: onDismiss == null
            ? null
            : IconButton(icon: const Icon(Icons.close), onPressed: onDismiss),
      ),
    );
  }
}
