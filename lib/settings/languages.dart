import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../generated/l10n.dart';
import '../state/settings/setting_state.dart';
import '../util/extension_helper.dart';

class LanguagesSetting extends StatelessWidget {
  const LanguagesSetting({super.key});

  Widget _langListTile(BuildContext context, String lang, Locale? locale) =>
      RadioListTile(
        value: locale,
        title: Text(lang, style: context.textTheme.bodyMedium),
        dense: true,
        contentPadding: const EdgeInsets.symmetric(horizontal: 20),
      );

  @override
  Widget build(BuildContext context) {
    final systemLocale = basicLocaleListResolution(
      PlatformDispatcher.instance.locales,
      S.delegate.supportedLocales,
    );
    return Selector<SettingState, Locale?>(
      selector: (_, settings) => settings.localeOverride.get(),
      builder: (context, locale, _) => RadioGroup<Locale>(
        onChanged: context.settingState.localeOverride.set,
        groupValue: locale,
        child: Column(
          children: [
            _langListTile(
              context,
              "${context.s.systemDefault} ($systemLocale)",
              null,
            ),
            _langListTile(context, 'English', Locale('en')),
            _langListTile(context, '简体中文', Locale('zh_Hans')),
            _langListTile(context, 'Français', Locale('fr')),
            _langListTile(context, 'Español', Locale('es')),
            _langListTile(context, 'Português', Locale('pt')),
            _langListTile(context, 'Italiano', Locale('it')),
            _langListTile(context, 'Türkçe', Locale('tr')),
            _langListTile(context, 'Ελληνικά', Locale('el')),
            Divider(height: 1),
          ],
        ),
      ),
    );
  }
}
