import 'package:country_flags/country_flags.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:line_icons/line_icons.dart';

import '../settings/settings_widgets.dart';
import '../util/extension_helper.dart';
import '../widgets/custom_widget.dart';

const String version = '0.10.0';

class AboutApp extends StatelessWidget {
  const AboutApp({super.key});

  @override
  Widget build(BuildContext context) {
    OverlayEntry createOverlayEntry(TapDownDetails detail) {
      // RenderBox renderBox = context.findRenderObject();
      final offset = detail.globalPosition;
      return OverlayEntry(
        builder: (constext) => Positioned(
          left: offset.dx - 5,
          top: offset.dy - 120,
          child: Container(
            width: 20,
            height: 120,
            color: Colors.transparent,
            alignment: Alignment.topCenter,
            child: HeartSet(height: 120, width: 20),
          ),
        ),
      );
    }

    final s = context.s;
    return SettingsPage(
      title: s.homeToprightMenuAbout,
      sections: [
        SettingsSection(
          items: [
            Column(
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                Image.asset("assets/logo.png", height: 80),
                Text(s.version(version)),
              ],
            ),
            SizedBox(height: 20),
            Text(s.aboutDes, textAlign: TextAlign.center),
            SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // TextButton(
                //   onPressed: () =>
                //       'https://tsacdop.stonegate.me/#/privacy'.launchUrl,
                //   style: TextButton.styleFrom(
                //       foregroundColor: context.accentColor,
                //       textStyle: TextStyle(fontWeight: FontWeight.bold)),
                //   child: Text(
                //     s.privacyPolicy,
                //   ),
                // ),
                // Container(
                //   margin: const EdgeInsets.symmetric(horizontal: 5),
                //   height: 4,
                //   width: 4,
                //   decoration: BoxDecoration(
                //       color: context.accentColor, shape: BoxShape.circle),
                // ),
                // TextButton(
                //   onPressed: () =>
                //       'https://tsacdop.stonegate.me/#/changelog'
                //           .launchUrl,
                //   style: TextButton.styleFrom(
                //       foregroundColor: context.accentColor,
                //       textStyle: TextStyle(fontWeight: FontWeight.bold)),
                //   child: Text(s.changelog,
                //       style: TextStyle(color: context.accentColor)),
                // ),
              ],
            ),
            // _listItem(context, 'Twitter @tsacdop',
            //     LineIcons.twitter, 'https://twitter.com/tsacdop'),
          ],
        ),
        SettingsSection(
          title: s.contribute,
          items: [
            SettingsTile(
              title: "GitHub",
              leading: Icon(LineIcons.alternateGithub),
              onTap: (_) => "https://github.com/Lojcs/tsacdop".launchUrl(),
            ),
            SettingsTile(
              title: s.suggestName,
              leading: Icon(Icons.chat),
              onTap: (_) =>
                  "https://github.com/Lojcs/tsacdop/discussions/41".launchUrl(),
            ),
            SettingsTile(
              title: s.translate,
              subtitle: s.localizationWeblate,
              leading: SvgPicture.asset("assets/weblate_logo.svg", width: 24),
              onTap: (_) => "https://hosted.weblate.org/projects/tsacdop-fork"
                  .launchUrl(),
            ),
            SettingsTile(
              title: s.keepAndroidOpen,
              subtitle: s.keepAndroidOpenDes,
              leading: Icon(Icons.lock_outline, color: Colors.deepOrange[400]),
              onTap: (_) => "https://keepandroidopen.org/".launchUrl(),
            ),
            // _listItem(context, 'Telegram', LineIcons.telegram,
            //     'https://t.me/joinchat/Bk3LkRpTHy40QYC78PK7Qg'),
            // _listItem(
            //   context,
            //   'Reddit',
            //   LineIcons.redditLogo,
            //   'https://www.reddit.com/r/Tsacdop',
            // ),
            // Center(
            //   child: SizedBox(
            //     width: 200,
            //     child: ElevatedButton(
            //       onPressed: () =>
            //           'https://www.buymeacoffee.com/stonegate'
            //               .launchUrl,
            //       style: ElevatedButton.styleFrom(
            //         backgroundColor: Color(0xffffdd00),
            //         elevation: 0,
            //         enableFeedback: false,
            //       ),
            //       child: Container(
            //         height: 30.0,
            //         padding: EdgeInsets.symmetric(horizontal: 4.0),
            //         alignment: Alignment.center,
            //         child: Row(
            //           mainAxisAlignment: MainAxisAlignment.center,
            //           mainAxisSize: MainAxisSize.min,
            //           children: <Widget>[
            //             Text(
            //               'Buy Me A Coffee',
            //               style: TextStyle(
            //                 fontWeight: FontWeight.w500,
            //                 color: Colors.white,
            //               ),
            //             ),
            //             SizedBox(width: 10),
            //             Image(
            //               image:
            //                   AssetImage('assets/buymeacoffee.png'),
            //               height: 20,
            //               fit: BoxFit.fitHeight,
            //             ),
            //           ],
            //         ),
            //       ),
            //     ),
            //   ),
            // ),
          ],
        ),
        SettingsSection(
          title: s.developer,
          items: [
            SettingsTile(
              title: "Lojcs",
              onTap: (context) => "https://github.com/Lojcs".launchUrl(),
            ),
          ],
        ),
        SettingsSection(
          title: s.developerOriginal,
          items: [
            SettingsTile(
              title: "Stonega",
              onTap: (context) => "https://github.com/stonega".launchUrl(),
            ),
          ],
        ),
        SettingsSection(
          title: s.translators,
          leading: Icon(Icons.favorite, color: Colors.red, size: 20),
          items: [
            _translatorInfo(context, name: 'Lord Tenebrous', flag: 'es'),
            _translatorInfo(context, name: 'Joel Israel', flag: 'es-mx'),
            _translatorInfo(context, name: 'ppp', flag: 'fr'),
            _translatorInfo(context, name: 'mondstern', flag: 'de'),
            _translatorInfo(context, name: 'Edoardo Maria Elidoro', flag: 'it'),
            _translatorInfo(context, name: 'Bruno Pinheiro', flag: 'pt'),
            _translatorInfo(context, name: 'Sergio Marques', flag: 'pt'),
            _translatorInfo(context, name: 'Lojcs', flag: 'tr'),
            _translatorInfo(context, name: 'Murat T. Akyuz', flag: 'tr'),
            _translatorInfo(context, name: 'Stonega', flag: "zh"),
            _translatorInfo(context, name: 'Atrate'),
          ],
        ),
        SettingsSection(
          items: [
            Container(
              height: 50,
              alignment: Alignment.center,
              child: GestureDetector(
                onTapDown: (detail) async {
                  OverlayEntry overlayEntry;
                  overlayEntry = createOverlayEntry(detail);
                  Overlay.of(context).insert(overlayEntry);
                  await Future.delayed(Duration(seconds: 2));
                  overlayEntry.remove();
                },
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: <Widget>[
                    Image.asset('assets/text.png', height: 25),
                    Padding(padding: EdgeInsets.symmetric(horizontal: 5)),
                    Icon(Icons.favorite, color: Colors.blue),
                    Padding(padding: EdgeInsets.symmetric(horizontal: 5)),
                    FlutterLogo(size: 18),
                  ],
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _translatorInfo(
    BuildContext context, {
    required String name,
    String? flag,
  }) => SettingsTile(
    title: name,
    leading: flag == null
        ? Icon(Icons.question_mark)
        : SizedBox(
            width: 24,
            child: FittedBox(
              child: CountryFlag.fromLanguageCode(
                flag,
                theme: ImageTheme(shape: RoundedRectangle(4)),
              ),
            ),
          ),
  );
}
