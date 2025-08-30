import 'dart:developer' as developer;

import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:xml/xml.dart' as xml;
import '../state/podcast_state.dart';
import '../util/extension_helper.dart';

class OpmlProgress extends Equatable {
  final void Function(OpmlProgress) setProgress;
  final int totalPodcasts;
  final int subscribedPodcasts;
  final int totalGroups;
  final int addedGroups;
  final bool addingGroups;
  final bool done;

  const OpmlProgress(this.setProgress,
      {this.totalPodcasts = 0,
      this.subscribedPodcasts = 0,
      this.totalGroups = 0,
      this.addedGroups = 0,
      this.addingGroups = false,
      this.done = false});

  double? get ratio => totalPodcasts == 0
      ? null
      : done
          ? 1
          : (subscribedPodcasts + addedGroups) / (totalPodcasts + totalGroups);
  void reset() => setProgress(OpmlProgress(setProgress));

  void begin(int podcasts, int groups) =>
      setProgress(copyWith(totalPodcasts: podcasts, totalGroups: groups));
  void subscribe() =>
      setProgress(copyWith(subscribedPodcasts: subscribedPodcasts + 1));

  void beginAddingGroups() => setProgress(copyWith(addingGroups: true));
  void addGroup() => setProgress(copyWith(addedGroups: addedGroups + 1));

  void finish() => setProgress(copyWith(done: true));

  OpmlProgress copyWith(
          {int? totalPodcasts,
          int? subscribedPodcasts,
          int? totalGroups,
          int? addedGroups,
          bool? addingGroups,
          bool? done}) =>
      OpmlProgress(setProgress,
          totalPodcasts: totalPodcasts ?? this.totalPodcasts,
          subscribedPodcasts: subscribedPodcasts ?? this.subscribedPodcasts,
          totalGroups: totalGroups ?? this.totalGroups,
          addedGroups: addedGroups ?? this.addedGroups,
          addingGroups: addingGroups ?? this.addingGroups,
          done: done ?? this.done);
  @override
  List<Object?> get props => [
        totalPodcasts,
        subscribedPodcasts,
        totalGroups,
        addedGroups,
        addingGroups,
        done
      ];
}

class OpmlImportPopup extends StatelessWidget {
  const OpmlImportPopup({super.key});

  @override
  Widget build(BuildContext context) {
    return Selector<PodcastState, OpmlProgress>(
      selector: (context, pState) => pState.opmlProgress,
      builder: (context, progress, _) {
        if (progress.done) {
          Future.delayed(Duration(seconds: 1), () {
            if (context.mounted) Navigator.of(context).pop();
          });
        }
        return PopScope(
          canPop: progress.done,
          child: AlertDialog(
            title: Text(context.s.importingOpml),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                LinearProgressIndicator(
                  value: progress.ratio,
                ),
                Text(switch (progress) {
                  OpmlProgress(done: true) => context.s.done,
                  OpmlProgress(
                    addingGroups: true,
                    addedGroups: var added,
                    totalGroups: var total
                  ) =>
                    "${context.s.notificationAddingGroups} $added/$total",
                  OpmlProgress(
                    addingGroups: false,
                    subscribedPodcasts: var added,
                    totalPodcasts: var total
                  ) =>
                    "${context.s.notificationSubscribing} $added/$total",
                })
              ],
            ),
          ),
        );
      },
    );
  }
}

class OmplOutline {
  final String? text;
  final String? xmlUrl;
  OmplOutline({this.text, this.xmlUrl});

  factory OmplOutline.parse(xml.XmlElement element) {
    return OmplOutline(
      text: element.getAttribute("text")?.trim(),
      xmlUrl: element.getAttribute("xmlUrl")?.trim(),
    );
  }
}

class PodcastsBackup {
  static xml.XmlNode omplBuilder(PodcastState podcastState) {
    final groupIds = podcastState.groupIds;
    var builder = xml.XmlBuilder();
    builder.processing('xml', 'version="1.0" encoding="UTF-8"');
    builder.element('ompl', nest: () {
      builder.attribute('version', '1.0');
      builder.element('head', nest: () {
        builder.element('title', nest: 'Tsacdop Feed Groups');
      });
      builder.element('body', nest: () {
        for (var groupId in groupIds) {
          final group = podcastState.getGroupById(groupId);
          builder.element('outline', nest: () {
            builder.attribute('text', group.name);
            builder.attribute('title', group.name);
            for (var e in group.podcastIds.map((id) => podcastState[id])) {
              builder.element(
                'outline',
                nest: () {
                  builder.attribute('type', 'rss');
                  builder.attribute('text', e.title);
                  builder.attribute('title', e.title);
                  builder.attribute('xmlUrl', e.rssUrl);
                },
                isSelfClosing: true,
              );
            }
          });
        }
      });
    });
    return builder.buildDocument();
  }

  static Map<String, List<OmplOutline>> parseOPML(String opml) {
    var data = <String, List<OmplOutline>>{};
    // var opml = file.readAsStringSync();
    var content = xml.XmlDocument.parse(opml);
    var title = content
        .findAllElements('head')
        .first
        .findElements('title')
        .first
        .innerText;
    developer.log(title, name: 'Import OPML');
    var groups = content.findAllElements('body').first.findElements('outline');
    if (title != 'Tsacdop Feed Groups') {
      var total = content
          .findAllElements('outline')
          .map((ele) => OmplOutline.parse(ele))
          .toList();
      data['Home'] = total;
      return data;
    }

    for (var element in groups) {
      var title = element.getAttribute('title');
      var total = element
          .findElements('outline')
          .map((ele) => OmplOutline.parse(ele))
          .toList();
      data[title!] = total;
    }
    return data;
  }
}
