import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../state/settings/setting_state.dart';
import '../util/extension_helper.dart';
import '../widgets/custom_widget.dart';
import '../widgets/general_dialog.dart';
import 'settings_widgets.dart';

class AppearanceSetting extends StatelessWidget {
  const AppearanceSetting({super.key});

  @override
  Widget build(BuildContext context) {
    final s = context.s;
    return SettingsPage(
      title: s.settingsLookAndFeel,
      sections: [
        SettingsSection(
          title: s.settingsColors,
          items: [
            SettingsRadioSheetTile(
              title: s.settingsTheme,
              selector: (_, settings) => settings.themeMode,
              valueToString: (_, value) => switch (value) {
                .system => s.systemDefault,
                .light => s.lightMode,
                .dark => s.darkMode,
              },
              getOptions: (_) async => ThemeMode.values,
            ),
            SettingsSwitchTile(
              title: s.settingsTrueBlack,
              subtitle: s.settingsTrueBlackDes,
              selector: (_, settings) => settings.trueBlack,
            ),
            SettingsSwitchTile(
              title: s.settingsUseSystemAccentColor,
              selector: (_, settings) => settings.useSystemAccentColor,
            ),
            SettingsValueTile(
              title: s.settingsAccentColor,
              selector: (_, settings) => settings.accentColor,
              trailingBuilder: (context, value) => Container(
                height: 25,
                width: 25,
                decoration: BoxDecoration(shape: BoxShape.circle, color: value),
              ),
              onTap: (context) => generalDialog(
                context,
                title: Selector<SettingState, Color>(
                  selector: (context, settings) =>
                      context.settingState.accentColor.get(),
                  builder: (context, value, _) => Text.rich(
                    TextSpan(
                      text: context.s.chooseA,
                      children: [
                        TextSpan(
                          text: ' ${context.s.color}',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: value,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                content: _ColorPicker(),
              ),
            ),
          ],
        ),
        SettingsSection(
          title: s.fontStyle,
          items: [
            SettingsValueTile(
              title: s.showNotesFonts,
              selector: (_, settings) => settings.showNotesFont,
              bodyBuilder: (context, value) => Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children:
                    [
                          TextStyle(),
                          GoogleFonts.getFont("Martel"),
                          GoogleFonts.getFont("Bitter"),
                        ]
                        .map(
                          (textStyle) => InkWell(
                            onTap: () => context.settingState.showNotesFont.set(
                              textStyle,
                            ),
                            borderRadius: BorderRadius.circular(10.0),
                            child: Container(
                              height: 60,
                              width: 80,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(
                                  color: textStyle == value
                                      ? context.primaryColor.withAlpha(70)
                                      : context.primaryColorDark,
                                ),
                                color: textStyle == value
                                    ? context.primaryColor.withAlpha(70)
                                    : Colors.transparent,
                              ),
                              alignment: Alignment.center,
                              child: Text(
                                'Show\nnotes',
                                textAlign: TextAlign.center,
                                style: textStyle,
                              ),
                            ),
                          ),
                        )
                        .toList(),
              ),
            ),
          ],
        ),
        SettingsSection(
          title: s.interaction,
          items: [
            SettingsSliderTile(
              title: s.haptics,
              subtitle: s.hapticsDes,
              selector: (_, settings) => settings.hapticsStrength,
              valueToString: (_, value) => value.toString(),
              valueToDouble: (_, value) => value.toDouble(),
              doubleToValue: (_, value) => value.toInt(),
              min: -4,
              max: 4,
              disableValue: -100,
              defaultValue: 0,
              divisions: 9,
            ),
          ],
        ),
      ],
    );
  }
}

class _ColorPicker extends StatefulWidget {
  const _ColorPicker();
  @override
  __ColorPickerState createState() => __ColorPickerState();
}

class __ColorPickerState extends State<_ColorPicker>
    with SingleTickerProviderStateMixin {
  TabController? _controller;
  int? _index;
  @override
  void initState() {
    super.initState();
    _index = 0;
    _controller = TabController(length: Colors.primaries.length, vsync: this)
      ..addListener(() {
        setState(() => _index = _controller!.index);
      });
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 400,
      height: 300,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          SizedBox(
            height: 48,
            child: TabBar(
              labelPadding: EdgeInsets.symmetric(horizontal: 8),
              controller: _controller,
              indicatorColor: Colors.transparent,
              indicatorSize: TabBarIndicatorSize.tab,
              isScrollable: true,
              dividerHeight: 0,
              tabAlignment: TabAlignment.start,
              tabs: Colors.primaries
                  .mapIndexed(
                    (i, color) => Tab(
                      child: Container(
                        height: 24,
                        width: 24,
                        decoration: BoxDecoration(
                          border: i == _index
                              ? Border.all(color: Colors.grey[400]!, width: 2)
                              : null,
                          shape: .circle,
                          color: color,
                        ),
                      ),
                    ),
                  )
                  .toList(),
            ),
          ),
          Expanded(
            child: TabBarView(
              physics: const ClampingScrollPhysics(),
              controller: _controller,
              viewportFraction: 1,
              children: Colors.primaries
                  .map<Widget>(
                    (color) => ScrollConfiguration(
                      behavior: NoGrowBehavior(),
                      child: GridView.count(
                        primary: false,
                        padding: .symmetric(horizontal: 8),
                        crossAxisSpacing: 8,
                        mainAxisSpacing: 8,
                        crossAxisCount: 3,
                        childAspectRatio: 2,
                        children: [
                          color.shade100,
                          color.shade200,
                          color.shade300,
                          color.shade400,
                          color.shade500,
                          color.shade600,
                          color.shade700,
                          color.shade800,
                          color.shade900,
                          ..._accentList(switch (color) {
                            Colors.red => Colors.redAccent,
                            Colors.pink => Colors.pinkAccent,
                            Colors.deepOrange => Colors.deepOrangeAccent,
                            Colors.orange => Colors.orangeAccent,
                            Colors.amber => Colors.amberAccent,
                            Colors.yellow => Colors.yellowAccent,
                            Colors.lime => Colors.limeAccent,
                            Colors.lightGreen => Colors.lightGreenAccent,
                            Colors.green => Colors.greenAccent,
                            Colors.teal => Colors.tealAccent,
                            Colors.cyan => Colors.cyanAccent,
                            Colors.lightBlue => Colors.lightBlueAccent,
                            Colors.blue => Colors.blueAccent,
                            Colors.indigo => Colors.indigoAccent,
                            Colors.purple => Colors.purpleAccent,
                            Colors.deepPurple => Colors.deepPurpleAccent,
                            _ => null,
                          }),
                        ].map((color) => _colorCircle(color)).toList(),
                      ),
                    ),
                  )
                  .toList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _colorCircle(Color color) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: context.radiusSmall,
        onTap: () => context.settingState.accentColor.set(color),
        child: Selector<SettingState, bool>(
          selector: (context, settings) =>
              color == context.settingState.accentColor.get(),
          builder: (context, value, _) => Container(
            decoration: BoxDecoration(
              border: value
                  ? Border.all(color: Colors.grey[400]!, width: 4)
                  : null,
              borderRadius: context.radiusSmall,
              color: color,
            ),
          ),
        ),
      ),
    );
  }

  List<Color> _accentList(MaterialAccentColor? color) => color == null
      ? []
      : [color.shade100, color.shade200, color.shade400, color.shade700];
}
