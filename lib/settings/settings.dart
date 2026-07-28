import 'package:feature_discovery/feature_discovery.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:line_icons/line_icons.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:url_launcher/url_launcher_string.dart';

import '../home/about.dart';
import '../intro_slider/app_intro.dart';
import '../util/extension_helper.dart';
import '../util/locales.dart';
import '../widgets/feature_discovery.dart';
import '../widgets/general_dialog.dart';
import 'data_backup.dart';
import 'history.dart';
import 'interface.dart';
import 'playback.dart';
import 'settings_widgets.dart';
import 'storage.dart';
import 'syncing.dart';
import 'appearance.dart';

class Settings extends StatelessWidget {
  const Settings({super.key});

  Widget _feedbackItem(
    BuildContext context,
    IconData icon,
    String name,
    String url,
  ) => ListTile(
    onTap: () {
      url.launchUrl();
      Navigator.pop(context);
    },
    dense: true,
    title: Row(
      children: [
        Icon(icon, size: 20),
        SizedBox(width: 20),
        Text(name, maxLines: 2, style: context.textTheme.bodyMedium),
      ],
    ),
  );

  @override
  Widget build(BuildContext context) {
    final s = context.s;
    return SettingsPage(
      title: s.settings,
      sections: [
        SettingsSection(
          title: s.settingsPrefrence,
          items: [
            SettingsTile(
              title: s.settingsLookAndFeel,
              subtitle: s.settingsLookAndFeelDes,
              leading: Icon(LineIcons.adjust, color: context.primaryColor),
              onTap: (context) => Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => AppearanceSetting()),
              ),
            ),
            SettingsTile(
              title: s.settingsInterface,
              subtitle: s.settingsInterfaceDes,
              leading: Icon(LineIcons.stopCircle, color: Colors.blueAccent),
              onTap: (context) => Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => InterfaceSetting()),
              ),
            ),
            SettingsTile(
              title: s.settingsPlayback,
              subtitle: s.settingsPlaybackDes,
              leading: Icon(LineIcons.playCircle, color: Colors.redAccent),
              onTap: (context) => Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => PlaybackSetting()),
              ),
            ),
            SettingsTile(
              title: s.settingsSyncing,
              subtitle: s.settingsSyncingDes,
              leading: Icon(
                LineIcons.alternateCloudDownload,
                color: Colors.yellow[700],
              ),
              onTap: (context) => Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => SyncingSetting()),
              ),
            ),
            SettingsTile(
              title: s.settingsDownloads,
              subtitle: s.settingsDownloadsDes,
              leading: Icon(LineIcons.save, color: Colors.green[700]),
              onTap: (context) => Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => DownloadsSetting()),
              ),
            ),
            SettingsTile(
              title: s.settingsHistory,
              subtitle: s.settingsHistoryDes,
              leading: Icon(Icons.update, color: Colors.indigo[700]),
              onTap: (context) => Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => PlayedHistory()),
              ),
            ),
            SettingsRadioSheetTile(
              title: s.settingsLanguage,
              selector: (_, settings) => settings.localeOverride,
              valueToString: (_, value) => localeNameOf(value),
              getOptions: (_) async => supportedLocales,
              leading: Icon(LineIcons.language, color: Colors.purpleAccent),
              sheetBody: ListTile(
                onTap: "https://hosted.weblate.org/projects/tsacdop-fork/"
                    .launchUrl,
                contentPadding: const EdgeInsets.only(left: 20, right: 20),
                dense: true,
                title: Align(
                  alignment: Alignment.center,
                  child: Image(
                    image: AssetImage('assets/weblate.png'),
                    height: 40,
                  ),
                ),
                subtitle: Padding(
                  padding: .only(top: 8),
                  child: Text(
                    context.s.localizationWeblate,
                    textAlign: .center,
                  ),
                ),
              ),
            ),
            SettingsTile(
              title: s.settingsBackup,
              subtitle: s.settingsBackupDes,
              leading: Icon(LineIcons.codeFile, color: Colors.lightGreen[700]),
              onTap: (context) => Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => DataBackup()),
              ),
            ),
          ],
        ),
        SettingsSection(
          title: s.settingsInfo,
          items: [
            SettingsTile(
              title: s.keepAndroidOpen,
              subtitle: s.keepAndroidOpenDes,
              leading: Icon(Icons.lock_outline, color: Colors.deepOrange[400]),
              onTap: (_) => "https://keepandroidopen.org/".launchUrl(),
            ),
            SettingsTile(
              title: s.homeToprightMenuAbout,
              leading: Icon(LineIcons.infoCircle),
              onTap: (context) => Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => AboutApp()),
              ),
            ),
            SettingsTile(
              title: s.settingsFeedback,
              subtitle: s.settingsFeedbackDes,
              leading: Icon(LineIcons.bug, color: Colors.pink[700]),
              onTap: (context) => showGeneralSheet(
                context,
                title: s.settingsFeedback,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  mainAxisAlignment: MainAxisAlignment.start,
                  children: [
                    _feedbackItem(
                      context,
                      LineIcons.github,
                      s.feedbackGithub,
                      'https://github.com/Lojcs/tsacdop/issues',
                    ),
                    _feedbackItem(
                      context,
                      LineIcons.envelopeOpenText,
                      s.feedbackEmail,
                      'mailto:<lojcsgit+tsacdop@gmail.com>?subject=Tsacdop Feedback',
                    ),
                    // _feedbackItem(LineIcons.googlePlay, s.feedbackPlay,
                    //     'https://play.google.com/store/apps/details?id=com.stonegate.tsacdop'),
                  ],
                ),
              ),
            ),
            SettingsTile(
              title: s.settingsLibraries,
              subtitle: s.settingsLibrariesDes,
              leading: Icon(LineIcons.bookOpen, color: Colors.purple[700]),
              onTap: (context) => Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => LicensePage()),
              ),
            ),
            SettingsTile(
              title: s.settingsDiscovery,
              leading: Icon(LineIcons.capsules, color: Colors.pinkAccent),
              onTap: (context) => generalDialog(
                context,
                title: Text(s.settingsDiscovery),
                content: Text(s.settingsDiscoveryDes),
                actions: <Widget>[
                  TextButton(
                    onPressed: Navigator.of(context).pop,
                    child: Text(
                      s.cancel,
                      style: TextStyle(
                        color: context.colorScheme.onSecondaryContainer,
                      ),
                    ),
                  ),
                  TextButton(
                    onPressed: () {
                      FeatureDiscovery.clearPreferences(context, <String>{
                        addFeature,
                        menuFeature,
                        playlistFeature,
                        groupsFeature,
                        addGroupFeature,
                        configureGroup,
                        configurePodcast,
                        podcastFeature,
                      });
                      Fluttertoast.showToast(
                        msg: s.toastDiscovery,
                        gravity: ToastGravity.BOTTOM,
                      );
                      Navigator.of(context).pop();
                    },
                    child: Text(
                      s.confirm,
                      style: TextStyle(color: context.error),
                    ),
                  ),
                ],
              ),
            ),
            SettingsTile(
              title: s.settingsAppIntro,
              leading: Icon(LineIcons.columns, color: Colors.blueGrey),
              onTap: (context) => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => SlideIntro(goto: Goto.settings),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
