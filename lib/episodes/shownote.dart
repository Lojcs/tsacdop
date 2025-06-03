import 'package:flutter/material.dart';
import 'package:flutter_html/flutter_html.dart';
import 'package:linkify/linkify.dart';
import 'package:provider/provider.dart';
import '../local_storage/sqflite_localpodcast.dart';
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
    return FutureBuilder<String?>(
      future: _getSDescription(),
      builder: (context, snapshot) {
        if (snapshot.hasData) {
          var description = snapshot.data!;
          if (description.isNotEmpty) {
            return Selector<AudioPlayerNotifier, int?>(
              selector: (_, audio) => audio.episodeId,
              builder: (_, playEpisodeId, __) {
                if (playEpisodeId == episodeId &&
                    !description.contains('#t=')) {
                  final linkList = linkify(description,
                      options: LinkifyOptions(humanize: false),
                      linkifiers: [TimeStampLinkifier()]);
                  for (final element in linkList) {
                    if (element is TimeStampElement) {
                      final time = element.timeStamp;
                      description = description.replaceFirst(time,
                          '<a rel="nofollow" href = "#t=$time">$time</a>');
                    }
                  }
                }
                return Selector<SettingState, TextStyle>(
                  selector: (_, settings) => settings.showNoteFontStyle,
                  builder: (_, data, __) => SelectionArea(
                    child: Html(
                      style: {
                        'html': Style.fromTextStyle(data.copyWith(fontSize: 14))
                            .copyWith(
                          padding: HtmlPaddings.symmetric(horizontal: 12),
                          color:
                              eState[episodeId].colorScheme(context).onSurface,
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
                      style: TextStyle(
                          color: context.textColor.withValues(alpha: 0.5))),
                ],
              ),
            );
          }
        } else {
          return Center();
        }
      },
    );
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

  Future<String> _getSDescription() async {
    final dbHelper = DBHelper();
    String description;
    description = (await dbHelper.getDescription(episodeId))!
        .replaceAll(RegExp(r'\s?<p>(<br>)?</p>\s?'), '')
        .replaceAll('\r', '')
        .trim();
    if (!description.contains('<')) {
      final linkList = linkify(description,
          options: LinkifyOptions(humanize: false),
          linkifiers: [UrlLinkifier(), EmailLinkifier()]);
      for (var element in linkList) {
        if (element is UrlElement) {
          description = description.replaceAll(element.url,
              '<a rel="nofollow" href = ${element.url}>${element.text}</a>');
        }
        if (element is EmailElement) {
          final address = element.emailAddress;
          description = description.replaceAll(address,
              '<a rel="nofollow" href = "mailto:$address">$address</a>');
        }
      }
      await dbHelper.saveEpisodeDes(episodeId, description: description);
    }
    return description;
  }
}
