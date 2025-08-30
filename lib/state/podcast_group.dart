import 'dart:core';
import 'dart:developer' as developer;
import 'dart:io';
import 'dart:isolate';
import 'dart:math' as math;
import 'dart:typed_data';

import 'package:audio_service/audio_service.dart';
import 'package:color_thief_dart/color_thief_dart.dart';
import 'package:dio/dio.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';
import 'package:flutter_isolate/flutter_isolate.dart';
import 'package:image/image.dart' as img;
import 'package:path_provider/path_provider.dart';
import 'package:path_provider_android/path_provider_android.dart';
import 'package:shared_preferences_android/shared_preferences_android.dart';
import 'package:uuid/uuid.dart';
import 'package:webfeed/webfeed.dart';
import 'package:workmanager/workmanager.dart';

import '../local_storage/key_value_storage.dart';
import '../local_storage/sqflite_localpodcast.dart';
import '../backup/gpodder_api.dart';
import '../type/fireside_data.dart';
import '../type/podcastbrief.dart';
import '../type/podcastgroup.dart';
import '../util/helpers.dart';

enum SubscribeState { none, start, subscribe, fetch, stop, exist, error }

class SubscribeItem {
  ///Rss url.
  String url;

  ///Rss title.
  String title;

  /// Subscribe status.
  SubscribeState subscribeState;

  /// Podcast id.
  String id;

  ///Avatar image link.
  String imgUrl;

  ///Podcast group, default Home.
  String group;

  SubscribeItem(
    this.url,
    this.title, {
    this.subscribeState = SubscribeState.none,
    this.id = '',
    this.imgUrl = '',
    this.group = '',
  });
}

final avatarColors = <String>[
  '388E3C',
  '1976D2',
  'D32F2F',
  '00796B',
];

@pragma('vm:entry-point')
Future<void> subIsolateEntryPoint(SendPort sendPort) async {
  if (Platform.isAndroid) SharedPreferencesAndroid.registerWith();
  if (Platform.isAndroid) PathProviderAndroid.registerWith();
  var items = <SubscribeItem>[];
  var running = false;
  var subReceivePort = ReceivePort();
  sendPort.send(subReceivePort.sendPort);

  Future<String> getColor(File file) async {
    final imageProvider = FileImage(file);
    var colorImage = await getImageFromProvider(imageProvider);
    var color = await getColorFromImage(colorImage);
    var primaryColor = color.toString();
    return primaryColor;
  }

  Future<void> subscribe(SubscribeItem item) async {
    var dbHelper = DBHelper();
    var rss = item.url;
    sendPort.send([item.title, item.url, 1]);
    var options = BaseOptions(
      connectTimeout: Duration(seconds: 30),
      receiveTimeout: Duration(seconds: 90),
    );

    try {
      var response = await Dio(options).get(rss);
      late RssFeed p;
      try {
        p = RssFeed.parse(response.data);
      } catch (e) {
        developer.log('Parse error', error: e);
        sendPort.send([item.title, item.url, 6]);
        await Future.delayed(Duration(seconds: 2));
        sendPort.send([item.title, item.url, 4]);
        items.removeWhere((element) => element.url == item.url);
        if (items.isNotEmpty) {
          await subscribe(items.first);
        } else {
          sendPort.send("done");
        }
      }
      developer.log('get dir');
      final dir = await getApplicationDocumentsDirectory();

      final realUrl =
          response.redirects.isEmpty ? rss : response.realUri.toString();

      final checkUrl = await dbHelper.checkPodcast(realUrl);

      /// If url not existe in database.
      if (checkUrl == null) {
        img.Image? thumbnail;
        String? imageUrl;
        try {
          var imageResponse = await Dio().get<List<int>>(p.itunes!.image!.href!,
              options: Options(
                responseType: ResponseType.bytes,
                receiveTimeout: Duration(seconds: 90),
              ));
          imageUrl = p.itunes!.image!.href;
          var image = img.decodeImage(Uint8List.fromList(imageResponse.data!))!;
          thumbnail = img.copyResize(image, width: 300);
        } catch (e) {
          try {
            var imageResponse = await Dio().get<List<int>>(item.imgUrl,
                options: Options(
                  responseType: ResponseType.bytes,
                  receiveTimeout: Duration(seconds: 90),
                ));
            imageUrl = item.imgUrl;
            var image =
                img.decodeImage(Uint8List.fromList(imageResponse.data!))!;
            thumbnail = img.copyResize(image, width: 300);
          } catch (e) {
            developer.log(e.toString(), name: 'Download image error');
            try {
              var index = math.Random().nextInt(3);
              var imageResponse = await Dio().get<List<int>>(
                  "https://ui-avatars.com/api/?size=300&background="
                  "${avatarColors[index]}&color=fff&name=${item.title}&length=2&bold=true",
                  options: Options(responseType: ResponseType.bytes));
              imageUrl = "https://ui-avatars.com/api/?size=300&background="
                  "${avatarColors[index]}&color=fff&name=${item.title}&length=2&bold=true";
              thumbnail =
                  img.decodeImage(Uint8List.fromList(imageResponse.data!));
            } catch (e) {
              developer.log(e.toString(), name: 'Donwload image error');
              sendPort.send([item.title, item.url, 6]);
              await Future.delayed(Duration(seconds: 2));
              sendPort.send([item.title, item.url, 4]);
              items.removeWhere((element) => element.url == item.url);
              if (items.isNotEmpty) {
                await subscribe(items.first);
              } else {
                sendPort.send("done");
              }
            }
          }
        }
        var uuid = Uuid().v4();
        File("${dir.path}/$uuid.png")
            .writeAsBytesSync(img.encodePng(thumbnail!));
        var imagePath = "${dir.path}/$uuid.png";
        var primaryColor = await getColor(File(imagePath));
        var author = p.itunes!.author ?? p.author ?? '';
        var provider = p.generator ?? '';
        var link = p.link ?? '';
        var funding = p.podcastFunding!.isNotEmpty
            ? [for (var f in p.podcastFunding!) f!.url]
            : <String>[];
        // var podcastLocal = PodcastBrief(p.title ?? "", imageUrl ?? "", realUrl,
        //     primaryColor, author, uuid, imagePath, provider, link, funding,
        //     description: p.description!);

        // await dbHelper.savePodcastLocal(podcastLocal);

        sendPort.send([item.title, item.url, 2, uuid, item.group]);

        if (provider.contains('fireside')) {
          var data = FiresideData(uuid, link);
          try {
            await data.fatchData();
          } catch (e) {
            developer.log(e.toString(), name: 'Fatch fireside data error');
          }
        }
        await dbHelper.savePodcastRss(p, uuid);

        sendPort.send([item.title, item.url, 3, uuid]);

        await Future.delayed(Duration(seconds: 2));

        sendPort.send([item.title, item.url, 4]);
        items.removeAt(0);
        if (items.isNotEmpty) {
          await subscribe(items.first);
        } else {
          sendPort.send("done");
        }
      } else {
        sendPort.send([item.title, realUrl, 5, checkUrl, item.group]);
        await Future.delayed(Duration(seconds: 2));
        sendPort.send([item.title, item.url, 4]);
        items.removeAt(0);
        if (items.isNotEmpty) {
          await subscribe(items.first);
        } else {
          sendPort.send("done");
        }
      }
    } catch (e) {
      developer.log('$e confirm');
      sendPort.send([item.title, item.url, 6]);
      await Future.delayed(Duration(seconds: 2));
      sendPort.send([item.title, item.url, 4]);
      items.removeWhere((element) => element.url == item.url);
      if (items.isNotEmpty) {
        await subscribe(items.first);
      } else {
        sendPort.send("done");
      }
    }
  }

  subReceivePort.distinct().listen((message) {
    if (message is List<dynamic>) {
      items.add(SubscribeItem(message[0], message[1],
          imgUrl: message[2], group: message[3]));
      if (!running) {
        subscribe(items.first);
        running = true;
      }
    }
  });
}
