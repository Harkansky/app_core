import 'package:flutter/material.dart';

import '../core_services.dart';
import 'links.dart';

/// Ready-made settings page: sound, music, vibration, restore purchases,
/// privacy policy, support contact and About. Add app-specific rows with
/// [extraTiles].
class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key, this.extraTiles = const []});

  final List<Widget> extraTiles;

  @override
  Widget build(BuildContext context) {
    final core = CoreServices.of(context);
    final settings = core.settings;
    final config = core.config;

    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: ListenableBuilder(
        listenable: settings,
        builder: (context, child) => ListView(
          children: [
            SwitchListTile(
              secondary: const Icon(Icons.volume_up_outlined),
              title: const Text('Sound effects'),
              value: settings.soundOn,
              onChanged: settings.setSoundOn,
            ),
            SwitchListTile(
              secondary: const Icon(Icons.music_note_outlined),
              title: const Text('Music'),
              value: settings.musicOn,
              onChanged: settings.setMusicOn,
            ),
            SwitchListTile(
              secondary: const Icon(Icons.vibration),
              title: const Text('Vibration'),
              value: settings.hapticsOn,
              onChanged: settings.setHapticsOn,
            ),
            ...extraTiles,
            const Divider(),
            ListTile(
              leading: const Icon(Icons.restore),
              title: const Text('Restore purchases'),
              onTap: () async {
                await core.purchases.restore();
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text(
                        'Restore requested. Items you own will reappear in a moment.',
                      ),
                    ),
                  );
                }
              },
            ),
            if (config.privacyPolicyUrl case final url?)
              ListTile(
                leading: const Icon(Icons.privacy_tip_outlined),
                title: const Text('Privacy policy'),
                onTap: () => openWebPage(url),
              ),
            if (config.supportEmail case final email?)
              ListTile(
                leading: const Icon(Icons.mail_outline),
                title: const Text('Contact support'),
                onTap: () => openSupportEmail(email, subject: config.appName),
              ),
            ListTile(
              leading: const Icon(Icons.info_outline),
              title: const Text('About'),
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
