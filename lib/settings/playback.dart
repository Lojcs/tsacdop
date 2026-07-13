import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:provider/provider.dart';

import '../state/settings/setting_state.dart';
import '../util/extension_helper.dart';
import '../widgets/custom_time_picker.dart';
import 'settings_widgets.dart';

const List kSecondsToSelect = [5, 10, 15, 20, 25, 30, 45, 60];
const List<double> kSpeedToSelect = [
  0.5,
  0.6,
  0.8,
  0.9,
  1.0,
  1.1,
  1.2,
  1.5,
  2.0,
  2.5,
  3.0,
  3.5,
  4.0,
  4.5,
  5.0,
];

class PlaybackSetting extends StatelessWidget {
  const PlaybackSetting({super.key});

  @override
  Widget build(BuildContext context) {
    final audio = context.audioState;
    final s = context.s;
    return SettingsPage(
      title: s.settingsPlayback,
      sections: [
        SettingsSection(
          title: s.homeMenuPlaylist,
          items: [
            SettingsSwitchTile(
              title: s.settingsMenuAutoPlay,
              subtitle: s.settingsAutoPlayDes,
              selector: (_, settings) => settings.autoPlay,
            ),
            SettingsSwitchTile(
              title: s.settingsMarkListenedSkip,
              subtitle: s.settingsMarkListenedSkipDes,
              selector: (_, settings) => settings.markPlayedWhenSkipped,
            ),
          ],
        ),
        SettingsSection(
          title: s.playback,
          items: [
            SettingsDurationSliderTile(
              title: s.settingsFastForwardSec,
              selector: (_, settings) => settings.fastForwardInterval,
              canDisable: false,
              type: .seconds,
            ),
            SettingsDurationSliderTile(
              title: s.settingsRewindSec,
              selector: (_, settings) => settings.rewindInterval,
              canDisable: false,
              type: .seconds,
            ),
            SettingsSliderTile<double>(
              title: s.settingsBoostVolume,
              subtitle: s.settingsBoostVolumeDes,
              selector: (_, settings) => settings.volumeBoostDecibels,
              valueToString: (_, value) => "$value dB",
              valueToDouble: (_, value) => value,
              doubleToValue: (_, value) => value,
              min: 0,
              max: 5,
              divisions: 10,
              disableValue: -1,
              canDisable: false,
              defaultValue: 1.5,
            ),
          ],
        ),
        SettingsSection(
          title: s.sleepTimer,
          items: [
            SettingsSwitchTile(
              title: s.settingsSTAuto,
              subtitle: s.settingsSTAutoDes,
              selector: (_, settings) => settings.sleepTimerAuto,
            ),
            SettingsTile(title: s.schedule, trailing: _ScheduleWidget()),
            SettingsSwitchTile(
              title: s.settingsSTWaitEpisodeEnd,
              subtitle: s.settingsSTWaitEpisodeEndDes,
              selector: (_, settings) => settings.sleepTimerWaitEpisodeEnd,
            ),
            SettingsDurationSliderTile(
              title: s.settingsSTDefaultTime,
              subtitle: s.settingsSTDefautTimeDes,
              selector: (_, settings) => settings.sleepTimerInterval,
              canDisable: false,
              type: .minutes,
            ),
          ],
        ),
      ],
    );
  }
}

class _ScheduleWidget extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    var settings = context.superSettingState;
    final s = context.s;
    return Selector<SettingState, (TimeOfDay, TimeOfDay)>(
      selector: (_, settings) => (
        settings.sleepTimerScheduleStart.get(),
        settings.sleepTimerScheduleEnd.get(),
      ),
      builder: (_, data, __) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 10.0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            InkWell(
              onTap: () async {
                final timeOfDay = await showCustomTimePicker(
                  context: context,
                  cancelText: s.cancel,
                  confirmText: s.confirm,
                  helpText: '',
                  initialTime: data.$1,
                );
                if (timeOfDay != null) {
                  if (timeOfDay != data.$2) {
                    await settings.sleepTimerScheduleStart.set(timeOfDay);
                  } else {
                    Fluttertoast.showToast(
                      msg: s.toastTimeEqualEnd,
                      gravity: ToastGravity.BOTTOM,
                    );
                  }
                }
              },
              borderRadius: BorderRadius.only(
                bottomLeft: Radius.circular(5),
                topLeft: Radius.circular(5),
              ),
              child: Material(
                color: Colors.transparent,
                child: Container(
                  decoration: BoxDecoration(
                    color: context.primaryColorDark,
                    borderRadius: BorderRadius.only(
                      bottomLeft: Radius.circular(5),
                      topLeft: Radius.circular(5),
                    ),
                  ),
                  padding: const EdgeInsets.all(8.0),
                  child: Text(s.from(data.$1.format(context))),
                ),
              ),
            ),
            InkWell(
              onTap: () async {
                final timeOfDay = await showCustomTimePicker(
                  context: context,
                  cancelText: s.cancel,
                  confirmText: s.confirm,
                  helpText: '',
                  initialTime: data.$2,
                );
                if (timeOfDay != null) {
                  if (timeOfDay != data.$1) {
                    await settings.sleepTimerScheduleEnd.set(timeOfDay);
                  } else {
                    Fluttertoast.showToast(
                      msg: s.toastTimeEqualEnd,
                      gravity: ToastGravity.BOTTOM,
                    );
                  }
                }
              },
              borderRadius: BorderRadius.only(
                bottomRight: Radius.circular(5),
                topRight: Radius.circular(5),
              ),
              child: Material(
                color: Colors.transparent,
                child: Container(
                  padding: const EdgeInsets.all(8.0),
                  decoration: BoxDecoration(
                    color: Colors.black54,
                    borderRadius: BorderRadius.only(
                      bottomRight: Radius.circular(5),
                      topRight: Radius.circular(5),
                    ),
                  ),
                  child: Text(
                    s.to(data.$2.format(context)),
                    style: TextStyle(color: Colors.white),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
