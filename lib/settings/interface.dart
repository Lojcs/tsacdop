import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../search/search_api.dart';
import '../search/search_web.dart';
import '../state/settings/setting_state.dart';
import '../type/media_control.dart';
import '../type/tab_configuration.dart';
import '../util/extension_helper.dart';
import '../widgets/action_bar.dart';
import '../widgets/general_dialog.dart';
import 'settings_widgets.dart';

class InterfaceSetting extends StatefulWidget {
  const InterfaceSetting({super.key});

  @override
  State<InterfaceSetting> createState() => _InterfaceSettingState();
}

class _InterfaceSettingState extends State<InterfaceSetting> {
  @override
  Widget build(BuildContext context) {
    final List<TextEditingController> nameControllers = [];
    final s = context.s;
    return SettingsPage(
      title: s.settingsInterface,
      sections: [
        SettingsSection(
          title: s.player,
          items: [
            SettingsValueTile(
              title: s.settingsMediaControls,
              subtitle: s.settingsMediaControlsDes,
              selector: (_, settings) => settings.notificationLayout,
              bodyBuilder: (context, value) => Container(
                decoration: BoxDecoration(
                  borderRadius: context.radiusSmall,
                  color: context.trueBlack
                      ? null
                      : context.colorScheme.surfaceContainerLow,
                  border: context.trueBlack
                      ? Border.all(color: context.colorScheme.surfaceBright)
                      : null,
                ),
                child: Row(
                  mainAxisSize: .min,
                  children: [
                    _notificationButton(value, 0),
                    _notificationButton(value, 1),
                    _notificationIcon(PlayControl(), false),
                    _notificationButton(value, 2),
                    _notificationButton(value, 3),
                  ],
                ),
              ),
            ),
          ],
        ),
        SettingsSection(
          title: s.search,
          items: [
            SettingsSwitchTile(
              title: s.settingsSearchMode,
              selector: (_, settings) => settings.searchMode,
            ),
            SettingsRadioSheetTile(
              title: s.settingsSearchApi,
              selector: (_, settings) => settings.searchApi,
              valueToString: (_, value) => value.name,
              getOptions: (_) async => SearchApi.values,
            ),
            SettingsRadioSheetTile(
              title: s.settingsSearchEngine,
              selector: (_, settings) => settings.searchEngine,
              valueToString: (_, value) => value.name,
              getOptions: (_) async => SearchEngine.values,
            ),
          ],
        ),
        SettingsSection(
          title: s.settingsDefaultFilters,
          items: [
            SettingsValueTile(
              title: s.settingsDefaultGridPodcast,
              selector: (_, settings) => settings.actionBarPodcasts,
              bodyBuilder: (context, value) => Container(
                margin: .only(bottom: 8),
                padding: .symmetric(vertical: 4),
                decoration: BoxDecoration(
                  borderRadius: context.radiusSmall,
                  color: context.trueBlack
                      ? null
                      : context.colorScheme.surfaceContainerLow,
                  border: context.trueBlack
                      ? Border.all(color: context.colorScheme.surfaceBright)
                      : null,
                ),
                child: LayoutBuilder(
                  builder: (context, constraints) => ActionBar(
                    onConfigurationChanged: (config) =>
                        context.superSettingState.actionBarPodcasts.set(config),
                    widgetsFirstRow: [
                      ActionBarDropdownSortBy(0, 0),
                      ActionBarSwitchSortOrder(0, 1),
                      ActionBarSpacer(0, 2),
                      ActionBarFilterPlayed(0, 3),
                      ActionBarFilterNew(0, 4),
                      ActionBarSwitchLayout(0, 5),
                    ],
                    widgetsSecondRow: [
                      ActionBarFilterDisplayVersion(1, 0),
                      ActionBarSpacer(1, 1),
                      ActionBarFilterDownloaded(1, 2),
                      ActionBarFilterLiked(1, 3),
                    ],
                    expandSecondRow: true,
                    sliver: false,
                    width: constraints.maxWidth - 5,
                    configuration: value,
                  ),
                ),
              ),
            ),
            SettingsValueTile(
              title: s.settingsDefaultFilterAndroidAuto,
              subtitle: s.settingsDefaultFilterAndroidAutoDes,
              selector: (_, settings) => settings.actionBarAndroidAuto,
              bodyBuilder: (context, value) => Container(
                margin: .only(bottom: 8),
                padding: .symmetric(vertical: 4),
                decoration: BoxDecoration(
                  borderRadius: context.radiusSmall,
                  color: context.trueBlack
                      ? null
                      : context.colorScheme.surfaceContainerLow,
                  border: context.trueBlack
                      ? Border.all(color: context.colorScheme.surfaceBright)
                      : null,
                ),
                child: LayoutBuilder(
                  builder: (context, constraints) => ActionBar(
                    onConfigurationChanged: (config) =>
                        context.superSettingState.actionBarPodcasts.set(config),
                    widgetsFirstRow: [
                      ActionBarFilterNew(0, 0),
                      ActionBarFilterLiked(0, 1),
                      ActionBarFilterDisplayVersion(0, 2),
                      ActionBarSpacer(0, 3),
                      ActionBarFilterDownloaded(0, 4),
                      ActionBarFilterPlayed(0, 5),
                    ],
                    sliver: false,
                    width: constraints.maxWidth - 5,
                    configuration: value,
                  ),
                ),
              ),
            ),
            SettingsValueTile(
              title: s.settingsHomeTabs,
              selector: (_, settings) => settings.homeTabs,
              bodyBuilder: (context, value) {
                return AnimatedSize(
                  duration: Duration(milliseconds: 300),
                  curve: Curves.easeInOut,
                  alignment: .topCenter,
                  child: Column(
                    mainAxisAlignment: .end,
                    children:
                        value.mapIndexed<Widget>((i, tab) {
                          if (i == nameControllers.length) {
                            nameControllers.add(
                              TextEditingController(text: tab.name),
                            );
                          } else {
                            nameControllers[i].text = tab.name;
                          }
                          return Container(
                            margin: .only(bottom: 8),
                            padding: .symmetric(vertical: 4),
                            decoration: BoxDecoration(
                              borderRadius: context.radiusSmall,
                              color: context.trueBlack
                                  ? null
                                  : context.colorScheme.surfaceContainerLow,
                              border: context.trueBlack
                                  ? Border.all(
                                      color: context.colorScheme.surfaceBright,
                                    )
                                  : null,
                            ),
                            height: 146,
                            child: Column(
                              children: [
                                SizedBox(
                                  height: 40,
                                  child: Row(
                                    mainAxisAlignment: .spaceBetween,
                                    children: [
                                      Flexible(
                                        child: TextFormField(
                                          textAlign: .center,
                                          decoration: InputDecoration(
                                            hintText: s.settingsHomeTabName,
                                            isDense: true,
                                            border: InputBorder.none,
                                          ),
                                          controller: nameControllers[i],
                                          // initialValue: tab.name,
                                          onChanged: (name) => context
                                              .superSettingState
                                              .homeTabs
                                              .set(
                                                [...value]
                                                  ..[i] = tab.copyWith(
                                                    name: name,
                                                  ),
                                              ),
                                        ),
                                      ),
                                      IconButton(
                                        onPressed: i == 0
                                            ? null
                                            : () => context
                                                  .superSettingState
                                                  .homeTabs
                                                  .set([...value]..removeAt(i)),
                                        icon: Icon(Icons.delete),
                                      ),
                                    ],
                                  ),
                                ),
                                LayoutBuilder(
                                  builder: (context, constraints) => ActionBar(
                                    onConfigurationChanged: (config) =>
                                        context.superSettingState.homeTabs.set(
                                          [...value]
                                            ..[i] = tab.copyWith(
                                              actionBarConfiguration: config,
                                            ),
                                        ),
                                    widgetsFirstRow: [
                                      ActionBarDropdownSortBy(0, 0),
                                      ActionBarSwitchSortOrder(0, 1),
                                      ActionBarDropdownGroups(0, 2),
                                      ActionBarSpacer(0, 3),
                                      ActionBarFilterPlayed(0, 4),
                                      ActionBarFilterNew(0, 5),
                                      ActionBarSwitchLayout(0, 6),
                                    ],
                                    widgetsSecondRow: [
                                      ActionBarDropdownPodcasts(1, 0),
                                      ActionBarFilterDisplayVersion(1, 1),
                                      ActionBarSearchTitle(1, 2),
                                      ActionBarSpacer(1, 3),
                                      ActionBarFilterDownloaded(1, 4),
                                      ActionBarFilterLiked(1, 5),
                                    ],
                                    expandSecondRow: true,
                                    sliver: false,
                                    width: constraints.maxWidth - 5,
                                    configuration: tab.actionBarConfiguration,
                                  ),
                                ),
                              ],
                            ),
                          );
                        }).toList()..add(
                          SizedBox(
                            width: 200,
                            child: TextButton(
                              onPressed: () =>
                                  context.superSettingState.homeTabs.set([
                                    ...value,
                                    HomeTabConfiguration(
                                      name: s.settingsHomeTabNew,
                                      actionBarConfiguration:
                                          ActionBarConfiguration(),
                                    ),
                                  ]),
                              child: Text(s.settingsHomeTabAdd),
                            ),
                          ),
                        ),
                  ),
                );
              },
            ),
          ],
        ),
      ],
    );
  }

  Widget _notificationButton(
    List<TsacdopMediaControl> controls,
    int index, [
    bool configurable = true,
  ]) {
    final control = controls[index];
    // configurable = configurable && index
    return Material(
      type: .transparency,
      borderRadius: context.radiusSmall,
      clipBehavior: .antiAlias,
      child: InkWell(
        onTap: configurable
            ? () {
                showGeneralSheet(
                  context,
                  title: "Pick button $index",
                  child: Selector<SettingState, List<TsacdopMediaControl>>(
                    selector: (context, settings) =>
                        settings.notificationLayout.get(),
                    builder: (context, value, _) =>
                        RadioGroup<TsacdopMediaControl>(
                          onChanged: (control) {
                            controls = [...controls];
                            controls[index] = control!;
                            context.superSettingState.notificationLayout.set(
                              controls,
                            );
                          },
                          groupValue: value[index],
                          child: Column(
                            children:
                                [
                                      if (index == 1) SkipToPreviousControl(),
                                      if (index == 2) SkipToNextControl(),
                                      StopControl(),
                                      FastForwardControl(),
                                      RewindControl(),
                                      NoneControl(),
                                    ]
                                    .map(
                                      (e) => RadioListTile(
                                        title: Text(e.label),
                                        secondary: Icon(e.icon),
                                        value: e,
                                      ),
                                    )
                                    .toList(),
                          ),
                        ),
                  ),
                );
              }
            : null,
        child: _notificationIcon(control),
      ),
    );
  }

  Widget _notificationIcon(
    TsacdopMediaControl control, [
    bool enabled = true,
  ]) => Container(
    width: 60,
    height: 72,
    padding: .all(6),
    child: Column(
      // mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Icon(control.icon, color: enabled ? null : Colors.grey[500]),
        Spacer(),
        Text(
          control.label,
          style: context.textTheme.labelMedium!.copyWith(
            color: enabled ? null : Colors.grey[500],
          ),
          textAlign: TextAlign.center,
          maxLines: 2,
          overflow: TextOverflow.clip,
        ),
        Spacer(),
      ],
    ),
  );
}
