import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';

import '../settings/downloads_manage.dart';
import '../util/extension_helper.dart';
import 'settings_widgets.dart';

class DownloadsSetting extends StatelessWidget {
  const DownloadsSetting({super.key});

  @override
  Widget build(BuildContext context) {
    final s = context.s;
    return SettingsPage(
      title: s.settingsDownloads,
      sections: [
        SettingsSection(
          title: s.settingStorage,
          items: [
            SettingsSwitchTile(
              title: s.settingsAutoDownload,
              subtitle: s.settingsAutoDownloadDes,
              selector: (_, settings) => settings.autoDownload,
            ),
            SettingsSwitchTile(
              title: s.settingsAutoDownloadNewPodcast,
              subtitle: s.settingsAutoDownloadNewPodcastDes,
              selector: (_, settings) => settings.newPodcastAutoDownload,
            ),
            SettingsRadioSheetTile(
              title: s.settingsDownloadPosition,
              selector: (_, settings) => settings.downloadStoragePath,
              valueToString: (_, value) async => value,
              getOptions: (context) async => [
                for (var dir in (await getExternalStorageDirectories())!)
                  dir.path,
              ],
            ),
            SettingsTile(
              title: s.settingsManageDownloadDes,
              onTap: (context) => Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => DownloadsManage()),
              ),
              trailing: Icon(Icons.chevron_right),
            ),
          ],
        ),
        SettingsSection(
          title: s.settingsAutoDelete,
          subtitle: s.settingsAutoDeleteDes,
          items: [
            SettingsSwitchTile(
              title: s.settingsAutoDeleteAfterPlayed,
              selector: (_, settings) => settings.autoDeleteAfterPlayed,
            ),
            SettingsDurationSliderTile(
              title: s.settingsAutoDeleteAfterTime,
              subtitle: s.settingsAutoDeleteAfterTimeDes,
              selector: (_, settings) => settings.autoDeleteAfterTime,
              type: .log,
            ),
            SettingsBytesSliderTile(
              title: s.settingsAutoDeleteOldestIfTotalAbove,
              subtitle: s.settingsAutoDeleteOldestIfTotalAboveDes,
              selector: (_, settings) => settings.autoDeleteOldestIfTotalAbove,
            ),
          ],
        ),
        SettingsSection(
          title: s.network,
          items: [
            SettingsSwitchTile(
              title: s.settingsAutoDownloadOnForbidden,
              subtitle: s.settingsAutoDownloadOnForbiddenDes,
              selector: (_, settings) => settings.autoDownloadOnForbidden,
            ),
            SettingsSwitchTile(
              title: s.settingsPauseDownloadOnForbiddenConnected,
              subtitle: s.settingsPauseDownloadOnForbiddenConnectedDes,
              selector: (_, settings) =>
                  settings.pauseDownloadOnForbiddenConnected,
            ),
            SettingsSwitchTile(
              title: s.settingsDownloadAskOnForbidden,
              subtitle: s.settingsDownloadAskOnForbiddenDes,
              selector: (_, settings) => settings.downloadAskOnForbidden,
            ),
            SettingsCheckboxSheetTile<ConnectivityResult>(
              title: s.settingsForbiddenDownloadConnections,
              subtitle: s.settingsForbiddenDownloadConnectionsDes,
              selector: (_, settings) => settings.forbiddenDownloadConnections,
              valueToString: (context, value) => switch (value) {
                .wifi => s.wifi,
                .mobile => s.mobileData,
                .vpn => s.vpn,
                .satellite => s.satellite,
                _ => "",
              },
              getOptions: (context) async => [.wifi, .mobile, .vpn, .satellite],
            ),
          ],
        ),
      ],
    );
  }
}
