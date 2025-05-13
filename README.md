![Tsacdop Banner][]

<!-- [![github action][]][github action link] -->
<!-- [![Localizely][]][localizely - website] -->
[![GitHub Release][]][github release - recent]
[![Github Downloads][]][github release - recent]
[![style: effective dart][]][effective dart pub]
[![License badge][]][license]
[![Weblate percentage][]][weblate engage]
[![weblate langouage count][]][weblate engage]
<!-- [![fdroid install][]][fdroid link] -->

## About

Enjoy podcasts with Tsacdop-Fork.

Tsacdop-Fork is a fork of Tsacdop, a podcast player developed with Flutter. A clean, simply beautiful, and friendly app, which is also free and open source.

This fork updates the ui, fixes bugs and adds ux features. Gpodder and podcast search apis are currently not supported.

Credit to upstream project [tsacdop](https://github.com/tsacdop/tsacdop), the Flutter team and all involved plugins, especially [webfeed](https://github.com/witochandra/webfeed), [Just_Audio](https://pub.dev/packages/just_audio), and [Provider](https://pub.dev/packages/provider).

## Download

[<img src="https://fdroid.gitlab.io/artwork/badge/get-it-on.png"
     alt="Get it on F-Droid"
     height="80">](https://f-droid.org/packages/dev.lojcs.tsacdop/)

Or download the latest APK from the [Releases Section](https://github.com/Lojcs/tsacdop/releases/latest).

## Features

* Podcast group management
* Playlists support
* Sleep timer / speed setting
* OPML file export and import
* Auto-syncing in the background
* Listening and subscription history record
* Dark mode / real dark mode / accent color
* Download for offline play
* Auto-download new episodes / auto-delete outdated downloads
* Settings backup
* Skip silence
* Boost volume
* Load local audio files

More to come...

## Preview

| Home Page | Groups | Podcast | Episode | Downloads | Audio Player
| ----- | ----- | ----- | ------ | ----- | ----- |
| ![][Homepage ScreenShot] | ![][Group Screenshot] | ![][Podcast Screenshot] | ![][Episode Screenshot]|![][Download Screenshot] | ![][Player Screenshot]

## Localization
Tsacdop-Fork has a [localization project](https://hosted.weblate.org/engage/tsacdop-fork/) on [Weblate](https://weblate.org/) thanks to their kind support of open source projects. You can translate untranslated strings, edit existing translations and add languages on the project page.

Translation status:

[<img src="https://hosted.weblate.org/widget/tsacdop-fork/multi-auto.svg"
     alt="Translation status"
     height="200">](https://hosted.weblate.org/engage/tsacdop-fork/)

## License

Tsacdop is licensed under the [GPL v3.0](https://github.com/lojcs/tsacdop/blob/master/LICENSE) license.

## Build

### Reproducible (On linux)

1. Download [build.sh](https://github.com/Lojcs/tsacdop/blob/main/tool/build.sh).

2. Create a [key.properties file](https://docs.flutter.dev/deployment/android#reference-the-keystore-from-the-app) pointing at your [keystore](https://docs.flutter.dev/deployment/android#create-an-upload-keystore).

3. Run build.sh.

### Without Script

1. Clone this repo.

``` 
git clone https://github.com/lojcs/tsacdop.git --recurse-submodules
```

2. Run the app with Android Studio or Visual Studio. Or the command line.

``` 
.flutter/bin/flutter pub get
.flutter/bin/flutter run
```

## Contribute 

If you have an issue or found a bug, please raise a GitHub issue. Pull requests are also welcome.

[You can find a list of known issues / my todo list here](https://github.com/users/Lojcs/projects/5/views/1)

<!-- ## Architecture

### Plugins

* Local storage
  + sqflite
  + shared_preferences
* Audio
  + just_audio
  + audio_service
* State management
  + provider
* Download
  + flutter_downloader
* Background task
  + workmanager

### Directory Structure

``` 
UI
src
└──home
   ├──home.dart [Homepage]
   ├──searc_podcast.dart [Search Page]
   └──playlist.dart [Playlist Page]
└──podcasts
   ├──podcast_manage.dart [Group Page]
   └──podcast_detail.dart [Podcast Page]
└──episodes
   └──episode_detail.dart [Episode Page]
└──settings
   └──setting.dart [Setting Page]

STATE
src
└──state
   ├──audio_state.dart [Audio State]
   ├──download_state.dart [Episode Download]
   ├──podcast_group.dart [Podcast Groups]
   ├──refresh_podcast.dart [Episode Refresh]
   └──setting_state.dart [Setting]

Service
src
└──service
   ├──api_service.dart [Podcast Search]
   ├──gpodder_api.dart [Gpodder intergate]
   └──ompl_builde.dart [OMPL export]
``` -->

## Contact

You can reach out to me on [Matrix](https://matrix.to/#/#tsacdop-fork:matrix.org) or email me [lojcsgit+tsacdop@gmail.com](mailto:<lojcsgit+tsacdop@gmail.com>). I'm not active on upstream's Telegram / Reddit groups.

<!-- Or you can join our [Telegram Group](https://t.me/joinchat/Bk3LkRpTHy40QYC78PK7Qg). -->

[Flutter Install]: https://flutter.dev/docs/get-started/install
[tsacdop banner]: preview/banner.png
[build status - cirrus]: https://circleci.com/gh/lojcs/tsacdop/tree/master.svg?style=shield
<!-- [github action]: https://github.com/lojcs/tsacdop/workflows/Flutter%20Build/badge.svg
[github action link]: https://github.com/lojcs/tsacdop/actions -->
[build status ]: https://circleci.com/gh/lojcs/tsacdop/tree/master
[github release]: https://img.shields.io/github/v/release/lojcs/tsacdop
[github release - recent]: https://github.com/lojcs/tsacdop/releases
[github downloads]: https://img.shields.io/github/downloads/lojcs/tsacdop/total?color=%230000d&label=downloads
<!-- [fdroid install]: https://img.shields.io/f-droid/v/com.stonegate.tsacdop?include_prereleases
[fdroid link]: https://f-droid.org/en/packages/com.stonegate.tsacdop/ -->
[weblate engage]: https://hosted.weblate.org/engage/tsacdop-fork/
[Weblate percentage]: https://hosted.weblate.org/widget/tsacdop-fork/svg-badge.svg
[weblate langouage count]: https://hosted.weblate.org/widget/tsacdop-fork/language-badge.svg
<!-- [google play - icon]: https://img.shields.io/badge/google-playStore-%2323CCC6
[google play]: https://play.google.com/store/apps/details?id=com.stonegate.tsacdop -->
[Homepage ScreenShot]: preview/light-home.png
[Group Screenshot]: preview/light-groups.png
[Podcast Screenshot]:preview/dark-podcast.png
[Episode Screenshot]: preview/dark-episode.png
[Download Screenshot]: preview/black-downloads.png
[Player Screenshot]: preview/black-player.png
[style: effective dart]: https://img.shields.io/badge/style-effective_dart-40c4ff.svg
[effective dart pub]: https://pub.dev/packages/effective_dart
[license]: https://github.com/lojcs/tsacdop/blob/master/LICENSE
[License badge]: https://img.shields.io/badge/license-GPLv3-yellow.svg
