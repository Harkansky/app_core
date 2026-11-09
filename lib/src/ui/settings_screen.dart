import 'package:flutter/material.dart';

import '../core_services.dart';
import '../l10n/core_localizations.dart';
import 'links.dart';

/// Ready-made settings page: sound, music, vibration, restore purchases,
/// privacy policy, ad privacy choices (only when the ad network requires
/// them), support contact and About. Add app-specific rows with [extraTiles].
class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key, this.extraTiles = const []});

  final List<Widget> extraTiles;

  @override
  Widget build(BuildContext context) {
    final core = CoreServices.of(context);
    final settings = core.settings;
    final config = core.config;
    final l10n = CoreLocalizations.of(context);
    final privacyUrl = config.privacyPolicyUrlFor(
      Localizations.localeOf(context),
    );

    return Scaffold(
      appBar: AppBar(title: Text(l10n.settingsTitle)),
      body: ListenableBuilder(
        listenable: Listenable.merge([settings, core.ads]),
        builder: (context, child) => ListView(
          children: [
            SwitchListTile(
              secondary: const Icon(Icons.volume_up_outlined),
              title: Text(l10n.soundEffects),
              value: settings.soundOn,
              onChanged: settings.setSoundOn,
            ),
            SwitchListTile(
              secondary: const Icon(Icons.music_note_outlined),
              title: Text(l10n.music),
              value: settings.musicOn,
              onChanged: settings.setMusicOn,
            ),
            SwitchListTile(
              secondary: const Icon(Icons.vibration),
              title: Text(l10n.vibration),
              value: settings.hapticsOn,
              onChanged: settings.setHapticsOn,
            ),
            ...extraTiles,
            const Divider(),
            ListTile(
              leading: const Icon(Icons.restore),
              title: Text(l10n.restorePurchases),
              onTap: () async {
                await core.purchases.restore();
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(l10n.restoreRequested)),
                  );
                }
              },
            ),
            if (privacyUrl case final url?)
              ListTile(
                leading: const Icon(Icons.privacy_tip_outlined),
                title: Text(l10n.privacyPolicy),
                onTap: () => openWebPage(url),
              ),
            if (core.ads.privacyOptionsRequired)
              ListTile(
                leading: const Icon(Icons.shield_outlined),
                title: Text(l10n.privacySettings),
                subtitle: Text(l10n.adChoices),
                onTap: core.ads.showPrivacyOptions,
              ),
            if (config.supportEmail case final email?)
              ListTile(
                leading: const Icon(Icons.mail_outline),
                title: Text(l10n.contactSupport),
                onTap: () => openSupportEmail(email, subject: config.appName),
              ),
            ListTile(
              leading: const Icon(Icons.info_outline),
              title: Text(l10n.about),
              onTap: () => showAboutDialog(
                context: context,
                applicationName: config.appName,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
