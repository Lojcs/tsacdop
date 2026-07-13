import 'package:flutter/material.dart';
import '../util/extension_helper.dart';
import 'settings_widgets.dart';

class SyncingSetting extends StatelessWidget {
  const SyncingSetting({super.key});

  @override
  Widget build(BuildContext context) {
    final s = context.s;
    return SettingsPage(
      title: s.settingsSyncing,
      sections: [
        SettingsSection(
          title: s.settingsSyncing,
          items: [
            SettingsSwitchTile(
              title: s.settingsEnableSyncing,
              subtitle: s.settingsEnableSyncingDes,
              selector: (_, settings) => settings.autoSync,
            ),
            SettingsDurationSliderTile(
              title: s.settingsSyncingInterval,
              selector: (_, settings) => settings.autoSyncInterval,
              type: .hours,
              canDisable: false,
            ),
          ],
        ),
      ],
    );
  }
}
