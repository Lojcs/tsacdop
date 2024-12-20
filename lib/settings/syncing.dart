import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:tsacdop/local_storage/sqflite_localpodcast.dart';
import 'package:tuple/tuple.dart';

import '../state/setting_state.dart';
import '../util/extension_helper.dart';
import '../widgets/custom_dropdown.dart';
import '../widgets/custom_widget.dart';

class SyncingSetting extends StatefulWidget {
  const SyncingSetting({Key? key}) : super(key: key);

  @override
  _SyncingSettingState createState() => _SyncingSettingState();
}

class _SyncingSettingState extends State<SyncingSetting> {
  @override
  Widget build(BuildContext context) {
    final s = context.s;
    var settings = Provider.of<SettingState>(context, listen: false);
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: context.overlay,
      child: Scaffold(
        backgroundColor: context.background,
        appBar: AppBar(
          title: Text(
            s.settingsSyncing,
            style: context.textTheme.titleLarge,
          ),
          leading: CustomBackButton(),
          elevation: 0,
          scrolledUnderElevation: 0,
          backgroundColor: context.background,
        ),
        body: SingleChildScrollView(
          child: Selector<SettingState, Tuple3<bool?, int?, VersionPolicy?>>(
            selector: (_, settings) => Tuple3(settings.autoUpdate,
                settings.updateInterval, settings.versionPolicy),
            builder: (_, data, __) => Column(
              mainAxisAlignment: MainAxisAlignment.start,
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                Padding(
                  padding: const EdgeInsets.fromLTRB(70, 20, 70, 10),
                  child: Text(s.settingsSyncing,
                      style: context.textTheme.bodyLarge!
                          .copyWith(color: context.accentColor)),
                ),
                ListTile(
                  onTap: () {
                    if (settings.autoUpdate!) {
                      settings.autoUpdate = false;
                      settings.cancelWork();
                    } else {
                      settings.autoUpdate = true;
                      settings.setWorkManager(data.item2);
                    }
                  },
                  contentPadding:
                      const EdgeInsets.only(left: 70.0, right: 20, bottom: 10),
                  title: Text(s.settingsEnableSyncing),
                  subtitle: Text(s.settingsEnableSyncingDes),
                  trailing: Transform.scale(
                    scale: 0.9,
                    child: Switch(
                        value: data.item1!,
                        onChanged: (boo) async {
                          settings.autoUpdate = boo;
                          if (boo) {
                            settings.setWorkManager(data.item2);
                          } else {
                            settings.cancelWork();
                          }
                        }),
                  ),
                ),
                ListTile(
                  contentPadding: const EdgeInsets.only(left: 70.0, right: 20),
                  title: Text(s.settingsUpdateInterval),
                  subtitle: Text(s.settingsUpdateIntervalDes),
                  trailing: MyDropdownButton(
                      hint: Text(s.hoursCount(data.item2!)),
                      underline: Center(),
                      elevation: 1,
                      displayItemCount: 5,
                      value: data.item2,
                      onChanged: data.item1!
                          ? (dynamic value) async {
                              await settings.cancelWork();
                              settings.setWorkManager(value);
                            }
                          : (int i) {},
                      items: <int>[1, 2, 4, 8, 24, 48]
                          .map<DropdownMenuItem<int>>((e) {
                        return DropdownMenuItem<int>(
                            value: e, child: Text(s.hoursCount(e)));
                      }).toList()),
                ),
                Divider(height: 1),
                Padding(
                  padding: EdgeInsets.all(10.0),
                ),
                Container(
                  height: 30.0,
                  padding: EdgeInsets.symmetric(horizontal: 70),
                  alignment: Alignment.centerLeft,
                  child: Text(s.settingsEpisodeManagement,
                      style: context.textTheme.bodyLarge!
                          .copyWith(color: context.accentColor)),
                ),
                ListTile(
                    contentPadding: const EdgeInsets.symmetric(horizontal: 70),
                    title: Text(s.settingsEpisodeVersioning),
                    subtitle: Text(s.settingsEpisodeVersioningDes)),
                Container(
                    padding: EdgeInsets.symmetric(horizontal: 70),
                    child: MyDropdownButton(
                        hint: Text(_getVersionPolicyString(data.item3!)),
                        underline: Center(),
                        elevation: 1,
                        displayItemCount: 3,
                        value: data.item3,
                        onChanged: (VersionPolicy versionPolicy) async {
                          settings.versionPolicy = versionPolicy;
                        },
                        items: <VersionPolicy>[
                          VersionPolicy.New,
                          VersionPolicy.Old,
                          VersionPolicy.NewIfNoDownloaded
                        ].map<DropdownMenuItem<VersionPolicy>>((e) {
                          return DropdownMenuItem<VersionPolicy>(
                              value: e,
                              child: Text(_getVersionPolicyString(e)));
                        }).toList())),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _getVersionPolicyString(VersionPolicy? versionPolicy) {
    final s = context.s;
    switch (versionPolicy) {
      case VersionPolicy.New:
        return s.episodeVersioningNew;
      case VersionPolicy.Old:
        return s.episodeVersioningOld;
      case VersionPolicy.NewIfNoDownloaded:
        return s.episodeVersioningNewIfNotDownloaded;
      default:
        return '';
    }
  }
}
