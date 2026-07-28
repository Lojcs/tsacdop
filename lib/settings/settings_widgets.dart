import 'dart:math';

import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:line_icons/line_icons.dart';
import 'package:provider/provider.dart';

import '../state/settings/preference.dart';
import '../state/settings/setting_state.dart';
import '../type/requirement_combinator.dart';
import '../type/theme_data.dart';
import '../util/extension_helper.dart';
import '../widgets/custom_widget.dart';
import '../widgets/general_dialog.dart';

/// A settings page.
class SettingsPage extends StatelessWidget {
  /// Title of the page.
  final String title;

  /// Sections in the page.
  final List<SettingsSection> sections;

  const SettingsPage({required this.title, required this.sections, super.key});

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion(
      value: context.overlay,
      child: Scaffold(
        backgroundColor: context.surface,
        appBar: AppBar(
          title: Text(title, style: context.textTheme.titleLarge),
          leading: CustomBackButton(),
          elevation: 0,
          scrolledUnderElevation: 0,
          backgroundColor: context.surface,
        ),
        body: SafeArea(
          child: ListView(
            children: sections
                .expandIndexed(
                  (i, e) => i == sections.length - 1
                      ? [e]
                      : [
                          e,
                          Divider(
                            height: 10,
                            thickness: 1,
                            indent: 20,
                            endIndent: 20,
                          ),
                        ],
                )
                .toList(),
          ),
        ),
      ),
    );
  }
}

/// Section of settings items.
class SettingsSection extends StatelessWidget {
  /// Title of the section.
  final String title;

  /// Subtitle of the section.
  final String? subtitle;

  /// Items in the section.
  final List<Widget> items;

  const SettingsSection({
    required this.title,
    this.subtitle,
    required this.items,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(left: 20, right: 20),
      child: Column(
        children: [
          ListTile(
            minTileHeight: 30,
            contentPadding: .symmetric(horizontal: 10),
            title: Text(
              title,
              style: context.textTheme.titleMedium!.copyWith(
                color: context.primaryColor,
              ),
            ),
            subtitle: subtitle != null ? Text(subtitle!) : null,
            leading: SizedBox(),
          ),
          ...items,
        ],
      ),
    );
  }
}

/// Item in a settings section.
sealed class SettingsItem extends StatelessWidget {
  const SettingsItem({super.key});
}

/// Tile for a settings item.
class SettingsTile extends SettingsItem {
  /// Title of the tile.
  final String title;

  /// Subtitle of the tile.
  final String? subtitle;

  /// Trailing widget of the tile.
  final Widget? trailing;

  /// Leading widget of the tile.
  final Widget? leading;

  /// What happens if the tile is tapped.
  final void Function(BuildContext context)? onTap;

  /// Body that comes after the tile.
  final Widget? body;

  const SettingsTile({
    required this.title,
    this.subtitle,
    this.trailing,
    this.leading,
    this.onTap,
    this.body,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: .symmetric(horizontal: 10),
      child: Column(
        children: [
          ListTile(
            onTap: onTap == null ? null : () => onTap?.call(context),
            shape: ContinuousRectangleBorder(borderRadius: context.radiusLarge),
            contentPadding: .zero,
            minTileHeight: body == null ? null : 30,
            title: Text(title),
            subtitle: subtitle != null ? Text(subtitle!) : null,
            trailing: Padding(padding: .only(right: 8), child: trailing),
            leading: SizedBox(child: leading),
          ),
          if (body != null)
            Padding(
              padding: .only(left: 40, right: 8, bottom: 8),
              child: body!,
            ),
        ],
      ),
    );
  }
}

/// Settings tile that holds a preference as trailing widget.
class SettingsValueTile<T> extends SettingsTile {
  /// Function to select the preference
  final Pref<T> Function(BuildContext context, SettingState settings) selector;

  /// Builder for the trailing widget.
  final Widget Function(BuildContext context, T value)? trailingBuilder;

  /// Builder for the body widget.
  final Widget Function(BuildContext context, T value)? bodyBuilder;

  SettingsValueTile({
    required super.title,
    super.subtitle,
    required this.selector,
    this.trailingBuilder,
    this.bodyBuilder,
    super.leading,
    super.onTap,
    super.key,
  }) : super(
         trailing: trailingBuilder == null
             ? null
             : Selector<SettingState, T>(
                 selector: (context, settings) =>
                     selector(context, settings).get(),
                 builder: (context, value, _) =>
                     trailingBuilder(context, value),
               ),
         body: bodyBuilder == null
             ? null
             : Selector<SettingState, T>(
                 selector: (context, settings) =>
                     selector(context, settings).get(),
                 builder: (context, value, _) => bodyBuilder(context, value),
               ),
       );
}

/// Tile with switch next to it.
class SettingsSwitchTile extends SettingsValueTile<bool> {
  SettingsSwitchTile({
    required super.title,
    super.subtitle,
    required super.selector,
    super.leading,
    super.key,
  }) : super(
         trailingBuilder: (context, value) => Transform.scale(
           alignment: .centerRight,
           scale: 0.85,
           child: Switch(
             padding: .zero,
             value: value,
             onChanged: (newValue) =>
                 selector(context, context.settingState).set(newValue),
           ),
         ),
         onTap: (context) {
           var preference = selector(context, context.settingState);
           preference.set(!preference.get());
         },
       );
}

/// Tile with slider underneath and value printed next to it.
class SettingsSliderTile<T> extends SettingsItem {
  /// Title of the tile.
  final String title;

  /// Subtitle of the tile.
  final String? subtitle;

  /// Function to select the preference
  final Pref<T> Function(BuildContext context, SettingState settings) selector;

  /// Converter to print the value on screen.
  final String Function(BuildContext context, T value) valueToString;

  /// Converter to convert the value to double on slider.
  final double Function(BuildContext context, T value) valueToDouble;

  /// Converter to convert the double from slider to value.
  final T Function(BuildContext context, double value) doubleToValue;

  /// Minimum number in slider.
  final int min;

  /// Maximum number in slider.
  final int max;

  /// Division count of slider.
  final int divisions;

  /// Value to set when disabled.
  final T disableValue;

  /// Value to set when enabled.
  final T defaultValue;

  /// Wheter to show disable button.
  final bool canDisable;

  /// Leading widget of the tile.
  final Widget? leading;

  const SettingsSliderTile({
    required this.title,
    this.subtitle,
    required this.selector,
    required this.valueToString,
    required this.valueToDouble,
    required this.doubleToValue,
    required this.min,
    required this.max,
    required this.divisions,
    required this.disableValue,
    required this.defaultValue,
    this.canDisable = true,
    this.leading,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: .symmetric(horizontal: 10),
      child: Material(
        type: .transparency,
        shape: ContinuousRectangleBorder(borderRadius: context.radiusLarge),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: canDisable
              ? () {
                  var preference = selector(context, context.settingState);
                  preference.set(
                    preference.get() == disableValue
                        ? defaultValue
                        : disableValue,
                  );
                }
              : null,
          child: AnimatedSize(
            duration: Duration(milliseconds: 300),
            alignment: .topCenter,
            curve: Curves.easeOutQuad,
            child: Column(
              children: [
                ListTile(
                  contentPadding: .symmetric(vertical: 8),
                  minVerticalPadding: 0,
                  minTileHeight: 30,
                  title: Text(title),
                  subtitle: subtitle != null ? Text(subtitle!) : null,
                  trailing: canDisable
                      ? Padding(
                          padding: .only(right: 8),
                          child: Selector<SettingState, T>(
                            selector: (context, settings) =>
                                selector(context, settings).get(),
                            builder: (context, value, _) => Transform.scale(
                              alignment: .centerRight,
                              scale: 0.85,
                              child: Switch(
                                padding: .zero,
                                value: value != disableValue,
                                onChanged: (newValue) =>
                                    selector(context, context.settingState).set(
                                      value != disableValue
                                          ? disableValue
                                          : defaultValue,
                                    ),
                              ),
                            ),
                          ),
                        )
                      : null,
                  leading: SizedBox(child: leading),
                ),
                Selector<SettingState, T>(
                  selector: (context, settings) =>
                      selector(context, settings).get(),
                  builder: (context, value, _) => value != disableValue
                      ? Padding(
                          padding: .only(left: 40, right: 8, bottom: 8),
                          child: Row(
                            mainAxisSize: .max,
                            children: [
                              Expanded(
                                child: Slider(
                                  padding: .only(right: 12),
                                  label: valueToString(context, value),
                                  activeColor: context.primaryColor,
                                  inactiveColor: context.primaryColorDark,
                                  value: valueToDouble(context, value),
                                  min: min.toDouble(),
                                  max: max.toDouble(),
                                  divisions: divisions,
                                  onChanged: (val) {
                                    var preference = selector(
                                      context,
                                      context.settingState,
                                    );
                                    preference.set(doubleToValue(context, val));
                                  },
                                ),
                              ),
                              SizedBox(
                                width: 64,
                                child: Selector<SettingState, T>(
                                  selector: (context, settings) =>
                                      selector(context, settings).get(),
                                  builder: (context, value, _) =>
                                      value != disableValue
                                      ? Text(
                                          valueToString(context, value),
                                          style: context.textTheme.labelMedium,
                                        )
                                      : Center(),
                                ),
                              ),
                            ],
                          ),
                        )
                      : Center(),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

enum DurationSliderType { seconds, minutes, hours, days, log }

/// Tile with slider underneath and value printed next to it.
class SettingsDurationSliderTile extends SettingsSliderTile<Duration> {
  final DurationSliderType type;
  SettingsDurationSliderTile({
    required super.title,
    super.subtitle,
    required super.selector,
    required this.type,
    super.canDisable,
    super.leading,
    super.key,
  }) : super(
         valueToString: (context, value) => switch (type) {
           .minutes => value.toTime(),
           _ => value.toLocalString(context),
         },
         valueToDouble: (_, value) => switch (type) {
           .seconds => value.inSeconds.toDouble(),
           .minutes => value.inMinutes.toDouble(),
           .hours => value.inHours.toDouble(),
           .days => value.inDays.toDouble(),
           .log => switch (value) {
             const Duration(hours: 1) => 1,
             const Duration(hours: 6) => 2,
             const Duration(days: 1) => 3,
             const Duration(days: 3) => 4,
             const Duration(days: 7) => 5,
             const Duration(days: 30) => 6,
             const Duration(days: 365) => 7,
             _ => 4,
           },
         },
         doubleToValue: (_, value) => switch (type) {
           .seconds => Duration(seconds: value.toInt()),
           .minutes => Duration(minutes: value.toInt()),
           .hours => Duration(hours: value.toInt()),
           .days => Duration(days: value.toInt()),
           .log => switch (value) {
             1 => const Duration(hours: 1),
             2 => const Duration(hours: 6),
             3 => const Duration(days: 1),
             4 => const Duration(days: 3),
             5 => const Duration(days: 7),
             6 => const Duration(days: 30),
             7 => const Duration(days: 365),
             _ => const Duration(days: 3),
           },
         },
         min: 1,
         max: switch (type) {
           .seconds => 60,
           .minutes => 120,
           .hours => 24,
           .days => 30,
           .log => 7,
         },
         disableValue: .zero,
         defaultValue: switch (type) {
           .seconds => Duration(seconds: 30),
           .minutes => Duration(minutes: 30),
           .hours => Duration(days: 1),
           .days => Duration(days: 15),
           .log => Duration(days: 3),
         },
         divisions: switch (type) {
           .seconds => 12,
           .minutes => 8,
           .hours => 6,
           .days => 6,
           .log => 6,
         },
       );
}

/// Tile with slider underneath and value printed next to it.
class SettingsBytesSliderTile extends SettingsSliderTile<int> {
  static int mib6 = 64 * 1048576;
  SettingsBytesSliderTile({
    required super.title,
    super.subtitle,
    required super.selector,
    super.canDisable,
    super.leading,
    super.key,
  }) : super(
         valueToString: (context, value) {
           final int mibs = value ~/ 1048576;
           return mibs > 1024 ? "${mibs ~/ 1024} GiB" : "$mibs MiB";
         },
         valueToDouble: (_, value) => (log(value / mib6) * log2e).toDouble(),
         doubleToValue: (_, value) => mib6 * (2 << (value.toInt() - 1)),
         min: 1,
         max: 13,
         disableValue: 0,
         defaultValue: 1048576 * 1024 * 16,
         divisions: 12,
       );
}

/// Settings tile that holds a value as subtitle.
class SettingsValueSubtitleTile<T> extends SettingsItem {
  /// Title of the tile.
  final String title;

  /// Function to select the preference
  final Pref<T> Function(BuildContext context, SettingState settings) selector;

  /// Converter to print the value on screen.
  final String Function(BuildContext context, T value) valueToString;

  /// Leading widget of the tile.
  final Widget? leading;

  /// What happens if the tile is tapped.
  final void Function(BuildContext context)? onTap;

  const SettingsValueSubtitleTile({
    required this.title,
    required this.selector,
    required this.valueToString,
    this.leading,
    this.onTap,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      minTileHeight: 30,
      onTap: onTap == null ? null : () => onTap?.call(context),
      shape: ContinuousRectangleBorder(borderRadius: context.radiusLarge),
      contentPadding: .symmetric(horizontal: 10),
      title: Text(title),
      subtitle: Selector<SettingState, T>(
        selector: (context, settings) => selector(context, settings).get(),
        builder: (context, value, _) => Text(valueToString(context, value)),
      ),
      leading: SizedBox(child: leading),
    );
  }
}

/// Tile that opens a bottom sheet with radio buttons.
class SettingsRadioSheetTile<T> extends SettingsValueSubtitleTile<T> {
  /// Options for the radio buttons.
  final Future<List<T>> Function(BuildContext context) getOptions;

  const SettingsRadioSheetTile({
    required super.title,
    required super.selector,
    required super.valueToString,
    required this.getOptions,
    super.leading,
    super.key,
  });

  @override
  void Function(BuildContext context)? get onTap => _onTap;

  void _onTap(BuildContext context) async {
    final options = await getOptions(context);
    if (context.mounted) {
      showGeneralSheet(
        context,
        title: title,
        child: Selector<SettingState, T>(
          selector: (context, settings) => selector(context, settings).get(),
          builder: (context, value, _) => RadioGroup<T>(
            groupValue: value,
            onChanged: (value) =>
                selector(context, context.settingState).set(value as T),
            child: Column(
              children: [
                for (var option in options)
                  RadioListTile(
                    title: Text(valueToString(context, option)),
                    value: option,
                  ),
              ],
            ),
          ),
        ),
      );
    }
  }
}

/// Tile with switch next to it.
class SettingsCheckboxSheetTile<T> extends SettingsValueTile<Set<T>> {
  /// Converter to print the value on screen.
  final String Function(BuildContext context, T value) valueToString;

  /// Options for the radio buttons.
  final Future<List<T>> Function(BuildContext context) getOptions;

  SettingsCheckboxSheetTile({
    required super.title,
    super.subtitle,
    required super.selector,
    required this.valueToString,
    required this.getOptions,
    super.leading,
    super.key,
  }) : super();
  @override
  void Function(BuildContext context)? get onTap => _onTap;

  void _onTap(BuildContext context) async {
    final options = await getOptions(context);
    if (context.mounted) {
      showGeneralSheet(
        context,
        title: title,
        child: Selector<SettingState, Set<T>>(
          selector: (context, settings) => selector(context, settings).get(),
          builder: (context, value, _) => Column(
            children: [
              for (var option in options)
                CheckboxListTile(
                  title: Text(valueToString(context, option)),
                  value: value.contains(option),
                  onChanged: (value) {
                    final setting = selector(context, context.settingState);
                    if (value == true) {
                      setting.set({...setting.get(), option});
                    } else {
                      setting.set(setting.get().difference({option}));
                    }
                  },
                ),
            ],
          ),
        ),
      );
    }
  }
}

/// Button similar to an action bar button to use in settings.
class SettingsActionButton extends StatelessWidget {
  const SettingsActionButton({
    required this.onPressed,
    required this.children,
    this.baseColor,
    this.active = false,
    this.connectLeft = false,
    this.connectRight = false,
    super.key,
  });

  final VoidCallback onPressed;
  final List<Widget> children;
  final Color? baseColor;
  final bool active;
  final bool connectLeft;
  final bool connectRight;

  @override
  Widget build(BuildContext context) {
    final cardColorScheme = baseColor == null
        ? context.cardColorScheme
        : CardColorScheme(
            getColorSchemeFromSeed(baseColor!, context.tbrightness),
            context.trueBlack,
          );
    final borderRadius = BorderRadius.horizontal(
      left: !connectLeft ? context.radiusSmall.bottomLeft : Radius.zero,
      right: !connectRight ? context.radiusSmall.bottomLeft : Radius.zero,
    );
    final side = BorderSide(color: cardColorScheme.saturated);
    final child = Material(
      borderRadius: borderRadius,
      clipBehavior: .antiAlias,
      color: active ? cardColorScheme.selected : cardColorScheme.card,
      child: InkWell(
        onTap: onPressed,
        child: Container(
          width: 60,
          height: 72,
          padding: .all(6),
          decoration: BoxDecoration(
            borderRadius: borderRadius,
            border: context.trueBlack
                ? Border(
                    top: side,
                    bottom: side,
                    left: connectLeft ? .none : side,
                    right: connectRight ? .none : side,
                  )
                : null,
          ),
          child: Column(mainAxisAlignment: .spaceEvenly, children: children),
        ),
      ),
    );
    if (context.trueBlack) {
      return IconTheme(
        data: IconThemeData(
          color: context.trueBlack ? cardColorScheme.saturated : null,
        ),
        child: child,
      );
    } else {
      return child;
    }
  }
}

class SettingsRequirementCombinatorSubsection
    extends SettingsValueTile<RequirementCombinator> {
  /// Items in the section.
  final List<Widget> items;

  SettingsRequirementCombinatorSubsection({
    required super.title,
    super.subtitle,
    required this.items,
    required super.selector,
    super.leading,
    super.key,
  }) : super(
         trailingBuilder: (context, value) => Row(
           mainAxisSize: .min,
           children: [
             SettingsActionButton(
               onPressed: () {
                 var preference = selector(context, context.settingState);
                 preference.set(.all);
               },
               active: value == .all,
               connectRight: true,
               children: [
                 Icon(LineIcons.diceD6),
                 Text(context.s.settingsRequirementsAll),
               ],
             ),
             SettingsActionButton(
               onPressed: () {
                 var preference = selector(context, context.settingState);
                 preference.set(.any);
               },
               active: value == .any,
               connectLeft: true,
               children: [
                 Icon(LineIcons.diceOne),
                 Text(context.s.settingsRequirementsAny),
               ],
             ),
           ],
         ),
         bodyBuilder: (context, value) => Column(children: items),
       );
}
