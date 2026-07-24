import 'package:flutter/material.dart';
import 'package:line_icons/line_icons.dart';
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
        SettingsSection(
          title: s.settingsEpisodeManagement,
          items: [
            SettingsTile(
              title: s.settingsNewEpisodes,
              subtitle: s.settingsNewEpisodesDes,
              leading: Icon(Icons.new_releases_outlined, color: Colors.red),
              onTap: (context) => Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => NewEpisodesSetting()),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class NewEpisodesSetting extends StatelessWidget {
  const NewEpisodesSetting({super.key});

  @override
  Widget build(BuildContext context) {
    final s = context.s;
    return SettingsPage(
      title: s.settingsNewEpisodes,
      sections: [
        SettingsSection(
          title: s.settingsNewEpisodesMark,
          subtitle: s.settingsNewEpisodesMarkDes,
          items: [
            SettingsSwitchTile(
              title: s.settingsNewEpisodesMarkDuplicate,
              subtitle: s.settingsNewEpisodesMarkDuplicateDes,
              selector: (_, settings) => settings.markNewAllowDuplicate,
            ),
            SettingsSwitchTile(
              title: s.settingsNewEpisodesMarkNewPodcast,
              subtitle: s.settingsNewEpisodesMarkNewPodcastDes,
              selector: (_, settings) => settings.markNewAllowNewSubscription,
            ),
            SettingsRequirementCombinatorSubsection(
              title: s.settingsRequirements,
              subtitle: s.settingsRequirementsDes,
              selector: (_, settings) => settings.markNewRequirementCombinator,
              items: [
                SettingsSwitchTile(
                  title: s.settingsNewEpisodesMarkUnseen,
                  subtitle: s.settingsNewEpisodesMarkUnseenDes,
                  selector: (_, settings) => settings.markNewRequireUnseen,
                ),
                SettingsDurationSliderTile(
                  title: s.settingsNewEpisodesMarkAge,
                  subtitle: s.settingsNewEpisodesMarkAgeDes,
                  selector: (_, settings) => settings.markNewRequireAgeMax,
                  type: .log,
                ),
              ],
            ),
          ],
        ),
        SettingsSection(
          title: s.settingsNewEpisodesUnmark,
          subtitle: s.settingsNewEpisodesUnmarkDes,
          items: [
            SettingsSwitchTile(
              title: s.settingsNewEpisodesUnmarkWaitSync,
              subtitle: s.settingsNewEpisodesUnmarkWaitSyncDes,
              selector: (_, settings) => settings.unmarkNewWaitForSync,
            ),
            SettingsRequirementCombinatorSubsection(
              title: s.settingsRequirements,
              subtitle: s.settingsRequirementsDes,
              selector: (_, settings) =>
                  settings.unmarkNewRequirementCombinator,
              items: [
                SettingsSwitchTile(
                  title: s.settingsNewEpisodesUnmarkInteracted,
                  subtitle: s.settingsNewEpisodesUnmarkInteractedDes,
                  selector: (_, settings) =>
                      settings.unmarkNewRequireInteracted,
                ),
                SettingsSwitchTile(
                  title: s.settingsNewEpisodesUnmarkPlayed,
                  subtitle: s.settingsNewEpisodesUnmarkPlayedDes,
                  selector: (_, settings) => settings.unmarkNewRequirePlayed,
                ),
                SettingsDurationSliderTile(
                  title: s.settingsNewEpisodesUnmarkAge,
                  subtitle: s.settingsNewEpisodesUnmarkAgeDes,
                  selector: (_, settings) => settings.unmarkNewRequireAgeMin,
                  type: .log,
                ),
              ],
            ),
          ],
        ),
      ],
    );
  }
}
