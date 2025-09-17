import 'package:flutter/material.dart';
import 'package:flutter_html/flutter_html.dart';
import 'package:provider/provider.dart';
import '../state/audio_state.dart';
import '../state/setting_state.dart';
import '../util/extension_helper.dart';

class ShowNote extends StatelessWidget {
  final int episodeId;
  const ShowNote({required this.episodeId, super.key});

  @override
  Widget build(BuildContext context) {
    final audio = context.audioState;
    final eState = context.episodeState;
    final s = context.s;
    final description = eState[episodeId].showNotes;
    if (description.isNotEmpty) {
      return Selector<AudioPlayerNotifier, int?>(
        selector: (_, audio) => audio.episodeId,
        builder: (_, playEpisodeId, __) {
          return Selector<SettingState, TextStyle>(
            selector: (_, settings) => settings.showNoteFontStyle,
            builder: (_, data, __) => SelectionArea(
              child: Html(
                style: {
                  'html':
                      Style.fromTextStyle(data.copyWith(fontSize: 14)).copyWith(
                    padding: HtmlPaddings.symmetric(horizontal: 12),
                    color: eState[episodeId].colorScheme(context).onSurface,
                  ),
                  'a': Style(
                    color: context.accentColor,
                    textDecoration: TextDecoration.none,
                  ),
                },
                data: description,
                onLinkTap: (url, _, __) {
                  if (url!.substring(0, 3) == '#t=') {
                    final seconds = _getTimeStamp(url);
                    if (playEpisodeId == episodeId) {
                      audio.seekTo(seconds! * 1000);
                    }
                  } else {
                    url.launchUrl;
                  }
                },
              ),
            ),
          );
        },
      );
    } else {
      return Container(
        height: context.width,
        alignment: Alignment.center,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Image(
              image: AssetImage('assets/shownote.png'),
              height: 100.0,
            ),
            Padding(padding: EdgeInsets.all(5.0)),
            Text(s.noShownote,
                textAlign: TextAlign.center,
                style:
                    TextStyle(color: context.textColor.withValues(alpha: 0.5))),
          ],
        ),
      );
    }
  }

  int? _getTimeStamp(String url) {
    final time = url.substring(3).trim();
    final data = time.split(':');
    int? seconds;
    if (data.length == 3) {
      seconds = int.tryParse(data[0])! * 3600 +
          int.tryParse(data[1])! * 60 +
          int.tryParse(data[2])!;
    } else if (data.length == 2) {
      seconds = int.tryParse(data[0])! * 60 + int.tryParse(data[1])!;
    }
    return seconds;
  }
}
