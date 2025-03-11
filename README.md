![Tsacdop Banner][]

<!-- [![github action][]][github action link] -->
<!-- [![Localizely][]][localizely - website] -->
[![GitHub Release][]][github release - recent]
[![Github Downloads][]][github release - recent]
[![style: effective dart][]][effective dart pub]
[![License badge][]][license]
<!-- [![fdroid install][]][fdroid link] -->

## About

Enjoy podcasts with Tsacdop-Fork.

Tsacdop-Fork is a fork of Tsacdop, a podcast player developed with Flutter. A clean, simply beautiful, and friendly app, which is also free and open source.

This fork updates the ui, fixes bugs and adds ux features. Gpodder and podcast search apis are currently not supported.

Credit to upstream project [tsacdop](https://github.com/tsacdop/tsacdop), the Flutter team and all involved plugins, especially [webfeed](https://github.com/witochandra/webfeed), [Just_Audio](https://pub.dev/packages/just_audio), and [Provider](https://pub.dev/packages/provider).

<!-- The podcast search engine is powered by, [ListenNotes](https://listennotes.com) & [PodcastIndex](https://podcastindex.org/). -->

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

Currently only has localizations already present in upstream (Chinese, French, Spanish, Portuguese, Italian, Turkish).  
Until I figure out how to set up a better localization system, localization prs are welcome.
<!-- Please [Email](mailto:<lojcsgit+tsacdop@gmail.com>) me you'd like to contribute to support more languages! -->


<!-- Credit to [Localizely](https://localizely.com/) for kind support to open source projects. -->

<!-- ### ![English]

### ![Chinese Simplified]

### ![French] 

### ![Spanish]

### ![Portuguese] -->

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
<!-- [localizely]: https://img.shields.io/badge/dynamic/json?color=%2326c6da&label=localizely&query=%24.languages.length&url=https%3A%2F%2Fapi.localizely.com%2Fv1%2Fprojects%2Fbde4e9bd-4cb2-449b-9de2-18f231ddb47d%2Fstatus -->
<!-- [English]: https://img.shields.io/badge/dynamic/json?style=for-the-badge&color=%2323CCC6&label=English&query=%24.languages%5B3%5D.reviewedProgress&url=https%3A%2F%2Fapi.localizely.com%2Fv1%2Fprojects%2Fbde4e9bd-4cb2-449b-9de2-18f231ddb47d%2Fstatus&suffix=%
[Chinese Simplified]: https://img.shields.io/badge/dynamic/json?style=for-the-badge&color=%2323CCC6&label=Chinese%20Simplified&query=%24.languages%5B2%5D.reviewedProgress&url=https%3A%2F%2Fapi.localizely.com%2Fv1%2Fprojects%2Fbde4e9bd-4cb2-449b-9de2-18f231ddb47d%2Fstatus&suffix=%
[French]: https://img.shields.io/badge/dynamic/json?style=for-the-badge&color=%2323CCC6&label=French(ppp)&query=%24.languages%5B5%5D.reviewedProgress&url=https%3A%2F%2Fapi.localizely.com%2Fv1%2Fprojects%2Fbde4e9bd-4cb2-449b-9de2-18f231ddb47d%2Fstatus&suffix=%
[Spanish]: https://img.shields.io/badge/dynamic/json?style=for-the-badge&color=%2323CCC6&label=Spanish(Joel)&query=%24.languages%5B7%5D.reviewedProgress&url=https%3A%2F%2Fapi.localizely.com%2Fv1%2Fprojects%2Fbde4e9bd-4cb2-449b-9de2-18f231ddb47d%2Fstatus&suffix=%
[Portuguese]: https://img.shields.io/badge/dynamic/json?style=for-the-badge&color=%2323CCC6&label=portuguese(Bruno)&query=%24.languages%5B9%5D.reviewedProgress&url=https%3A%2F%2Fapi.localizely.com%2Fv1%2Fprojects%2Fbde4e9bd-4cb2-449b-9de2-18f231ddb47d%2Fstatus&suffix=%
[localizely - website]: https://localizely.com/ -->
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
