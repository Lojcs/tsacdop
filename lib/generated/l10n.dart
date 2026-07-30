// GENERATED CODE - DO NOT MODIFY BY HAND
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'intl/messages_all.dart';

// **************************************************************************
// Generator: Flutter Intl IDE plugin
// Made by Localizely
// **************************************************************************

// ignore_for_file: non_constant_identifier_names, lines_longer_than_80_chars
// ignore_for_file: join_return_with_assignment, prefer_final_in_for_each
// ignore_for_file: avoid_redundant_argument_values, avoid_escaping_inner_quotes

class S {
  S();

  static S? _current;

  static S get current {
    assert(_current != null,
        'No instance of S was loaded. Try to initialize the S delegate before accessing S.current.');
    return _current!;
  }

  static const AppLocalizationDelegate delegate = AppLocalizationDelegate();

  static Future<S> load(Locale locale) {
    final name = (locale.countryCode?.isEmpty ?? false)
        ? locale.languageCode
        : locale.toString();
    final localeName = Intl.canonicalizedLocale(name);
    return initializeMessages(localeName).then((_) {
      Intl.defaultLocale = localeName;
      final instance = S();
      S._current = instance;

      return instance;
    });
  }

  static S of(BuildContext context) {
    final instance = S.maybeOf(context);
    assert(instance != null,
        'No instance of S present in the widget tree. Did you add S.delegate in localizationsDelegates?');
    return instance!;
  }

  static S? maybeOf(BuildContext context) {
    return Localizations.of<S>(context, S);
  }

  /// `Tsacdop is an elegant and customizable podcast player built with Flutter.`
  String get aboutDes {
    return Intl.message(
      'Tsacdop is an elegant and customizable podcast player built with Flutter.',
      name: 'aboutDes',
      desc: '',
      args: [],
    );
  }

  /// `Add`
  String get add {
    return Intl.message(
      'Add',
      name: 'add',
      desc: 'Subscribe new podcast',
      args: [],
    );
  }

  /// `{count, plural, zero{} one{{count} episode in {groupName} added to playlist} other{{count} episodes in {groupName} added to playlist}}`
  String addEpisodeGroup(Object groupName, num count) {
    return Intl.plural(
      count,
      zero: '',
      one: '$count episode in $groupName added to playlist',
      other: '$count episodes in $groupName added to playlist',
      name: 'addEpisodeGroup',
      desc: '',
      args: [groupName, count],
    );
  }

  /// `{count, plural, zero{} one{{count} episode added to playlist} other{{count} episodes added to playlist}}`
  String addNewEpisodeAll(num count) {
    return Intl.plural(
      count,
      zero: '',
      one: '$count episode added to playlist',
      other: '$count episodes added to playlist',
      name: 'addNewEpisodeAll',
      desc: '',
      args: [count],
    );
  }

  /// `Add new episodes to playlist`
  String get addNewEpisodeTooltip {
    return Intl.message(
      'Add new episodes to playlist',
      name: 'addNewEpisodeTooltip',
      desc: '',
      args: [],
    );
  }

  /// `Add some groups`
  String get addSomeGroups {
    return Intl.message(
      'Add some groups',
      name: 'addSomeGroups',
      desc: 'Please add new groups',
      args: [],
    );
  }

  /// `After`
  String get after {
    return Intl.message(
      'After',
      name: 'after',
      desc:
          'Used in a button to select episodes after the selected one(s) on a list. Not used for time',
      args: [],
    );
  }

  /// `All`
  String get all {
    return Intl.message(
      'All',
      name: 'all',
      desc: '',
      args: [],
    );
  }

  /// `Api Search`
  String get apiSearch {
    return Intl.message(
      'Api Search',
      name: 'apiSearch',
      desc: '',
      args: [],
    );
  }

  /// `Auto download`
  String get autoDownload {
    return Intl.message(
      'Auto download',
      name: 'autoDownload',
      desc: '',
      args: [],
    );
  }

  /// `Back`
  String get back {
    return Intl.message(
      'Back',
      name: 'back',
      desc: '',
      args: [],
    );
  }

  /// `Before`
  String get before {
    return Intl.message(
      'Before',
      name: 'before',
      desc:
          'Used in a button to select episodes before the selected one(s) on a list. Not used for time',
      args: [],
    );
  }

  /// `Between`
  String get between {
    return Intl.message(
      'Between',
      name: 'between',
      desc:
          'Used in a button to select episodes between the selected one(s) on a list',
      args: [],
    );
  }

  /// `Boost volume`
  String get boostVolume {
    return Intl.message(
      'Boost volume',
      name: 'boostVolume',
      desc: 'Boost volume in player widget.',
      args: [],
    );
  }

  /// `Buffering`
  String get buffering {
    return Intl.message(
      'Buffering',
      name: 'buffering',
      desc: '',
      args: [],
    );
  }

  /// `CANCEL`
  String get cancel {
    return Intl.message(
      'CANCEL',
      name: 'cancel',
      desc: '',
      args: [],
    );
  }

  /// `Default`
  String get capitalDefault {
    return Intl.message(
      'Default',
      name: 'capitalDefault',
      desc: '',
      args: [],
    );
  }

  /// `Cellular data warning`
  String get cellularConfirm {
    return Intl.message(
      'Cellular data warning',
      name: 'cellularConfirm',
      desc: '',
      args: [],
    );
  }

  /// `Are you sure you want to use cellular data to download?`
  String get cellularConfirmDes {
    return Intl.message(
      'Are you sure you want to use cellular data to download?',
      name: 'cellularConfirmDes',
      desc: '',
      args: [],
    );
  }

  /// `Change layout`
  String get changeLayout {
    return Intl.message(
      'Change layout',
      name: 'changeLayout',
      desc: '',
      args: [],
    );
  }

  /// `Changelog`
  String get changelog {
    return Intl.message(
      'Changelog',
      name: 'changelog',
      desc: '',
      args: [],
    );
  }

  /// `Choose a`
  String get chooseA {
    return Intl.message(
      'Choose a',
      name: 'chooseA',
      desc: '',
      args: [],
    );
  }

  /// `Clear`
  String get clear {
    return Intl.message(
      'Clear',
      name: 'clear',
      desc: '',
      args: [],
    );
  }

  /// `Clear all`
  String get clearAll {
    return Intl.message(
      'Clear all',
      name: 'clearAll',
      desc: 'Clear all episodes in playlist.',
      args: [],
    );
  }

  /// `Close`
  String get close {
    return Intl.message(
      'Close',
      name: 'close',
      desc: '',
      args: [],
    );
  }

  /// `color`
  String get color {
    return Intl.message(
      'color',
      name: 'color',
      desc: '',
      args: [],
    );
  }

  /// `CONFIRM`
  String get confirm {
    return Intl.message(
      'CONFIRM',
      name: 'confirm',
      desc: '',
      args: [],
    );
  }

  /// `Confirmation`
  String get confirmation {
    return Intl.message(
      'Confirmation',
      name: 'confirmation',
      desc: '',
      args: [],
    );
  }

  /// `Contribute`
  String get contribute {
    return Intl.message(
      'Contribute',
      name: 'contribute',
      desc: '',
      args: [],
    );
  }

  /// `New playlist`
  String get createNewPlaylist {
    return Intl.message(
      'New playlist',
      name: 'createNewPlaylist',
      desc: '',
      args: [],
    );
  }

  /// `Dark mode`
  String get darkMode {
    return Intl.message(
      'Dark mode',
      name: 'darkMode',
      desc: '',
      args: [],
    );
  }

  /// `{count, plural, zero{Today} one{{count} day ago} other{{count} days ago}}`
  String daysAgo(num count) {
    return Intl.plural(
      count,
      zero: 'Today',
      one: '$count day ago',
      other: '$count days ago',
      name: 'daysAgo',
      desc: '',
      args: [count],
    );
  }

  /// `{count, plural, zero{{count} days} one{{count} day} other{{count} days}}`
  String daysCount(num count) {
    return Intl.plural(
      count,
      zero: '$count days',
      one: '$count day',
      other: '$count days',
      name: 'daysCount',
      desc: '',
      args: [count],
    );
  }

  /// `This is the default queue, can''t be removed.`
  String get defaultQueueReminder {
    return Intl.message(
      'This is the default queue, can\'\'t be removed.',
      name: 'defaultQueueReminder',
      desc: 'Remind user that default queue can\'t be removed.',
      args: [],
    );
  }

  /// `Default podcast search engine`
  String get defaultSearchEngine {
    return Intl.message(
      'Default podcast search engine',
      name: 'defaultSearchEngine',
      desc: '',
      args: [],
    );
  }

  /// `Choose the default podcast search engine`
  String get defaultSearchEngineDes {
    return Intl.message(
      'Choose the default podcast search engine',
      name: 'defaultSearchEngineDes',
      desc: 'Choose the default podcast search engine',
      args: [],
    );
  }

  /// `Delete`
  String get delete {
    return Intl.message(
      'Delete',
      name: 'delete',
      desc: '',
      args: [],
    );
  }

  /// `Deleted`
  String get deleted {
    return Intl.message(
      'Deleted',
      name: 'deleted',
      desc: '',
      args: [],
    );
  }

  /// `This episode has been deleted from the database`
  String get deletedEpisodeDesc {
    return Intl.message(
      'This episode has been deleted from the database',
      name: 'deletedEpisodeDesc',
      desc: '',
      args: [],
    );
  }

  /// `This podcast has been deleted from the database`
  String get deletedPodcastDesc {
    return Intl.message(
      'This podcast has been deleted from the database',
      name: 'deletedPodcastDesc',
      desc: '',
      args: [],
    );
  }

  /// `Deselect All`
  String get deselectAll {
    return Intl.message(
      'Deselect All',
      name: 'deselectAll',
      desc: '',
      args: [],
    );
  }

  /// `Details`
  String get details {
    return Intl.message(
      'Details',
      name: 'details',
      desc: '',
      args: [],
    );
  }

  /// `Developer`
  String get developer {
    return Intl.message(
      'Developer',
      name: 'developer',
      desc: '',
      args: [],
    );
  }

  /// `Original developer`
  String get developerOriginal {
    return Intl.message(
      'Original developer',
      name: 'developerOriginal',
      desc: '',
      args: [],
    );
  }

  /// `Device Storage`
  String get deviceStorage {
    return Intl.message(
      'Device Storage',
      name: 'deviceStorage',
      desc: 'Refers to files stored on user\'s device.',
      args: [],
    );
  }

  /// `Disabled`
  String get disabled {
    return Intl.message(
      'Disabled',
      name: 'disabled',
      desc: '',
      args: [],
    );
  }

  /// `Dismiss`
  String get dismiss {
    return Intl.message(
      'Dismiss',
      name: 'dismiss',
      desc: '',
      args: [],
    );
  }

  /// `Display Version`
  String get displayVersion {
    return Intl.message(
      'Display Version',
      name: 'displayVersion',
      desc:
          'The version of an episode displayed by default. Used with filterType.',
      args: [],
    );
  }

  /// `Done`
  String get done {
    return Intl.message(
      'Done',
      name: 'done',
      desc: '',
      args: [],
    );
  }

  /// `Download`
  String get download {
    return Intl.message(
      'Download',
      name: 'download',
      desc: '',
      args: [],
    );
  }

  /// `Download Date`
  String get downloadDate {
    return Intl.message(
      'Download Date',
      name: 'downloadDate',
      desc: 'Download Date sort order',
      args: [],
    );
  }

  /// `Downloaded`
  String get downloaded {
    return Intl.message(
      'Downloaded',
      name: 'downloaded',
      desc: '',
      args: [],
    );
  }

  /// `Downloading`
  String get downloading {
    return Intl.message(
      'Downloading',
      name: 'downloading',
      desc: '',
      args: [],
    );
  }

  /// `Download removed`
  String get downloadRemovedToast {
    return Intl.message(
      'Download removed',
      name: 'downloadRemovedToast',
      desc: '',
      args: [],
    );
  }

  /// `Downloading`
  String get downloadStart {
    return Intl.message(
      'Downloading',
      name: 'downloadStart',
      desc: 'Toast of downloading',
      args: [],
    );
  }

  /// `Duration`
  String get duration {
    return Intl.message(
      'Duration',
      name: 'duration',
      desc: 'Duration sort order',
      args: [],
    );
  }

  /// `Edit group name`
  String get editGroupName {
    return Intl.message(
      'Edit group name',
      name: 'editGroupName',
      desc: '',
      args: [],
    );
  }

  /// `Play until end`
  String get endOfEpisode {
    return Intl.message(
      'Play until end',
      name: 'endOfEpisode',
      desc: '',
      args: [],
    );
  }

  /// `{count, plural, zero{} one{Episode} other{Episodes}}`
  String episode(num count) {
    return Intl.plural(
      count,
      zero: '',
      one: 'Episode',
      other: 'Episodes',
      name: 'episode',
      desc: '',
      args: [count],
    );
  }

  /// `Fast forward`
  String get fastForward {
    return Intl.message(
      'Fast forward',
      name: 'fastForward',
      desc: '',
      args: [],
    );
  }

  /// `Fast rewind`
  String get fastRewind {
    return Intl.message(
      'Fast rewind',
      name: 'fastRewind',
      desc: '',
      args: [],
    );
  }

  /// `Tap to edit group`
  String get featureDiscoveryEditGroup {
    return Intl.message(
      'Tap to edit group',
      name: 'featureDiscoveryEditGroup',
      desc: '',
      args: [],
    );
  }

  /// `You can change group name or delete it here, but the home group can not be edited or deleted`
  String get featureDiscoveryEditGroupDes {
    return Intl.message(
      'You can change group name or delete it here, but the home group can not be edited or deleted',
      name: 'featureDiscoveryEditGroupDes',
      desc: '',
      args: [],
    );
  }

  /// `Episode view`
  String get featureDiscoveryEpisode {
    return Intl.message(
      'Episode view',
      name: 'featureDiscoveryEpisode',
      desc: '',
      args: [],
    );
  }

  /// `You can long press to play episode or add it to a playlist.`
  String get featureDiscoveryEpisodeDes {
    return Intl.message(
      'You can long press to play episode or add it to a playlist.',
      name: 'featureDiscoveryEpisodeDes',
      desc: '',
      args: [],
    );
  }

  /// `Long press to play episode instantly`
  String get featureDiscoveryEpisodeTitle {
    return Intl.message(
      'Long press to play episode instantly',
      name: 'featureDiscoveryEpisodeTitle',
      desc: '',
      args: [],
    );
  }

  /// `Tap to add group`
  String get featureDiscoveryGroup {
    return Intl.message(
      'Tap to add group',
      name: 'featureDiscoveryGroup',
      desc: '',
      args: [],
    );
  }

  /// `The Home group is the default group for new podcasts. You can create new groups and move podcasts to them as well as add podcasts to multiple groups.`
  String get featureDiscoveryGroupDes {
    return Intl.message(
      'The Home group is the default group for new podcasts. You can create new groups and move podcasts to them as well as add podcasts to multiple groups.',
      name: 'featureDiscoveryGroupDes',
      desc: '',
      args: [],
    );
  }

  /// `Long press to reorder podcasts`
  String get featureDiscoveryGroupPodcast {
    return Intl.message(
      'Long press to reorder podcasts',
      name: 'featureDiscoveryGroupPodcast',
      desc: '',
      args: [],
    );
  }

  /// `You can tap to see more options, or long press to reorder podcasts in group.`
  String get featureDiscoveryGroupPodcastDes {
    return Intl.message(
      'You can tap to see more options, or long press to reorder podcasts in group.',
      name: 'featureDiscoveryGroupPodcastDes',
      desc: '',
      args: [],
    );
  }

  /// `Tap to import OPML`
  String get featureDiscoveryOMPL {
    return Intl.message(
      'Tap to import OPML',
      name: 'featureDiscoveryOMPL',
      desc: '',
      args: [],
    );
  }

  /// `You can import OPML files, open settings or refresh all podcasts at once here.`
  String get featureDiscoveryOMPLDes {
    return Intl.message(
      'You can import OPML files, open settings or refresh all podcasts at once here.',
      name: 'featureDiscoveryOMPLDes',
      desc: '',
      args: [],
    );
  }

  /// `Tap to open playlist`
  String get featureDiscoveryPlaylist {
    return Intl.message(
      'Tap to open playlist',
      name: 'featureDiscoveryPlaylist',
      desc: '',
      args: [],
    );
  }

  /// `You can add episodes to playlists by yourself. Episodes will be automatically removed from playlists when played.`
  String get featureDiscoveryPlaylistDes {
    return Intl.message(
      'You can add episodes to playlists by yourself. Episodes will be automatically removed from playlists when played.',
      name: 'featureDiscoveryPlaylistDes',
      desc: '',
      args: [],
    );
  }

  /// `Podcast view`
  String get featureDiscoveryPodcast {
    return Intl.message(
      'Podcast view',
      name: 'featureDiscoveryPodcast',
      desc: '',
      args: [],
    );
  }

  /// `You can tap See All to add groups or manage podcasts.`
  String get featureDiscoveryPodcastDes {
    return Intl.message(
      'You can tap See All to add groups or manage podcasts.',
      name: 'featureDiscoveryPodcastDes',
      desc: '',
      args: [],
    );
  }

  /// `Scroll vertically to switch groups`
  String get featureDiscoveryPodcastTitle {
    return Intl.message(
      'Scroll vertically to switch groups',
      name: 'featureDiscoveryPodcastTitle',
      desc: '',
      args: [],
    );
  }

  /// `Tap to search for podcasts`
  String get featureDiscoverySearch {
    return Intl.message(
      'Tap to search for podcasts',
      name: 'featureDiscoverySearch',
      desc: '',
      args: [],
    );
  }

  /// `You can search by podcast title, key word or RSS link to subscribe to new podcasts.`
  String get featureDiscoverySearchDes {
    return Intl.message(
      'You can search by podcast title, key word or RSS link to subscribe to new podcasts.',
      name: 'featureDiscoverySearchDes',
      desc: '',
      args: [],
    );
  }

  /// `Write to me`
  String get feedbackEmail {
    return Intl.message(
      'Write to me',
      name: 'feedbackEmail',
      desc: '',
      args: [],
    );
  }

  /// `Submit issue`
  String get feedbackGithub {
    return Intl.message(
      'Submit issue',
      name: 'feedbackGithub',
      desc: '',
      args: [],
    );
  }

  /// `Rate on Play Store`
  String get feedbackPlay {
    return Intl.message(
      'Rate on Play Store',
      name: 'feedbackPlay',
      desc: 'Rate on Google Play Store.\nUser can tap to open play link.',
      args: [],
    );
  }

  /// `Join group`
  String get feedbackTelegram {
    return Intl.message(
      'Join group',
      name: 'feedbackTelegram',
      desc: '',
      args: [],
    );
  }

  /// `Filter`
  String get filter {
    return Intl.message(
      'Filter',
      name: 'filter',
      desc: '',
      args: [],
    );
  }

  /// `{type} Filter`
  String filterType(Object type) {
    return Intl.message(
      '$type Filter',
      name: 'filterType',
      desc:
          'To use with different episode filter types. Noun, not verb. Ex: {Downloaded} Filter, {Played} Filter, {Group} Filter...',
      args: [type],
    );
  }

  /// `Fonts`
  String get fonts {
    return Intl.message(
      'Fonts',
      name: 'fonts',
      desc: '',
      args: [],
    );
  }

  /// `Font style`
  String get fontStyle {
    return Intl.message(
      'Font style',
      name: 'fontStyle',
      desc: '',
      args: [],
    );
  }

  /// `Forward`
  String get forward {
    return Intl.message(
      'Forward',
      name: 'forward',
      desc: '',
      args: [],
    );
  }

  /// `From {time}`
  String from(Object time) {
    return Intl.message(
      'From $time',
      name: 'from',
      desc: '',
      args: [time],
    );
  }

  /// `Get started`
  String get getStarted {
    return Intl.message(
      'Get started',
      name: 'getStarted',
      desc: '',
      args: [],
    );
  }

  /// `Tap {icon} to search podcasts`
  String getStartedDes(Object icon) {
    return Intl.message(
      'Tap $icon to search podcasts',
      name: 'getStartedDes',
      desc: '',
      args: [icon],
    );
  }

  /// `Globally disabled`
  String get globallyDisabled {
    return Intl.message(
      'Globally disabled',
      name: 'globallyDisabled',
      desc: 'Indicates that a granular setting was disabled globally',
      args: [],
    );
  }

  /// `Good Night`
  String get goodNight {
    return Intl.message(
      'Good Night',
      name: 'goodNight',
      desc: '',
      args: [],
    );
  }

  /// `Congratulations! You  have linked gpodder.net account successfully. Tsacdop will automatically sync subscriptions on your device with your gpodder.net account.`
  String get gpodderLoginDes {
    return Intl.message(
      'Congratulations! You  have linked gpodder.net account successfully. Tsacdop will automatically sync subscriptions on your device with your gpodder.net account.',
      name: 'gpodderLoginDes',
      desc: '',
      args: [],
    );
  }

  /// `Group already exists`
  String get groupExisted {
    return Intl.message(
      'Group already exists',
      name: 'groupExisted',
      desc:
          'Group name validate in add group dialog. User can\'t add group with same name.',
      args: [],
    );
  }

  /// `Are you sure you want to delete this group? Podcasts will be moved to the Home group.`
  String get groupRemoveConfirm {
    return Intl.message(
      'Are you sure you want to delete this group? Podcasts will be moved to the Home group.',
      name: 'groupRemoveConfirm',
      desc: '',
      args: [],
    );
  }

  /// `{count, plural, zero{Group} one{Group} other{Groups}}`
  String groups(num count) {
    return Intl.plural(
      count,
      zero: 'Group',
      one: 'Group',
      other: 'Groups',
      name: 'groups',
      desc: '',
      args: [count],
    );
  }

  /// `Haptic Feedback`
  String get haptics {
    return Intl.message(
      'Haptic Feedback',
      name: 'haptics',
      desc: 'Haptic Feedback (vibrations)',
      args: [],
    );
  }

  /// `Toggle haptic feedback and adjust its intensity. (Requires device support)`
  String get hapticsDes {
    return Intl.message(
      'Toggle haptic feedback and adjust its intensity. (Requires device support)',
      name: 'hapticsDes',
      desc: 'Haptic Feedback settings item description',
      args: [],
    );
  }

  /// `Hide listened`
  String get hideListenedSetting {
    return Intl.message(
      'Hide listened',
      name: 'hideListenedSetting',
      desc: '',
      args: [],
    );
  }

  /// `Hide podcast discovery`
  String get hidePodcastDiscovery {
    return Intl.message(
      'Hide podcast discovery',
      name: 'hidePodcastDiscovery',
      desc: 'Hide podcast discovery',
      args: [],
    );
  }

  /// `Hide podcast discovery in search page`
  String get hidePodcastDiscoveryDes {
    return Intl.message(
      'Hide podcast discovery in search page',
      name: 'hidePodcastDiscoveryDes',
      desc: '',
      args: [],
    );
  }

  /// `See All`
  String get homeGroupsSeeAll {
    return Intl.message(
      'See All',
      name: 'homeGroupsSeeAll',
      desc: '',
      args: [],
    );
  }

  /// `Playlist`
  String get homeMenuPlaylist {
    return Intl.message(
      'Playlist',
      name: 'homeMenuPlaylist',
      desc: '',
      args: [],
    );
  }

  /// `Sort by`
  String get homeSubMenuSortBy {
    return Intl.message(
      'Sort by',
      name: 'homeSubMenuSortBy',
      desc: '',
      args: [],
    );
  }

  /// `Favorite`
  String get homeTabMenuFavotite {
    return Intl.message(
      'Favorite',
      name: 'homeTabMenuFavotite',
      desc: '',
      args: [],
    );
  }

  /// `Recent`
  String get homeTabMenuRecent {
    return Intl.message(
      'Recent',
      name: 'homeTabMenuRecent',
      desc: '',
      args: [],
    );
  }

  /// `About`
  String get homeToprightMenuAbout {
    return Intl.message(
      'About',
      name: 'homeToprightMenuAbout',
      desc: '',
      args: [],
    );
  }

  /// `Import OPML`
  String get homeToprightMenuImportOMPL {
    return Intl.message(
      'Import OPML',
      name: 'homeToprightMenuImportOMPL',
      desc: '',
      args: [],
    );
  }

  /// `Refresh all`
  String get homeToprightMenuRefreshAll {
    return Intl.message(
      'Refresh all',
      name: 'homeToprightMenuRefreshAll',
      desc: '',
      args: [],
    );
  }

  /// `Hosted on {host}`
  String hostedOn(Object host) {
    return Intl.message(
      'Hosted on $host',
      name: 'hostedOn',
      desc: '',
      args: [host],
    );
  }

  /// `{count, plural, zero{This hour} one{{count} hour ago} other{{count} hours ago}}`
  String hoursAgo(num count) {
    return Intl.plural(
      count,
      zero: 'This hour',
      one: '$count hour ago',
      other: '$count hours ago',
      name: 'hoursAgo',
      desc: '',
      args: [count],
    );
  }

  /// `{count, plural, zero{0 hours} one{{count} hour} other{{count} hours}}`
  String hoursCount(num count) {
    return Intl.plural(
      count,
      zero: '0 hours',
      one: '$count hour',
      other: '$count hours',
      name: 'hoursCount',
      desc: '',
      args: [count],
    );
  }

  /// `Import`
  String get import {
    return Intl.message(
      'Import',
      name: 'import',
      desc: '',
      args: [],
    );
  }

  /// `Importing OPML file.`
  String get importingOpml {
    return Intl.message(
      'Importing OPML file.',
      name: 'importingOpml',
      desc: '',
      args: [],
    );
  }

  /// `Interaction`
  String get interaction {
    return Intl.message(
      'Interaction',
      name: 'interaction',
      desc: 'Interaction setting menu section title',
      args: [],
    );
  }

  /// `Integrate with {service}`
  String intergateWith(Object service) {
    return Intl.message(
      'Integrate with $service',
      name: 'intergateWith',
      desc: 'Integrate with',
      args: [service],
    );
  }

  /// `You can long press on episode card for quick actions.`
  String get introFourthPage {
    return Intl.message(
      'You can long press on episode card for quick actions.',
      name: 'introFourthPage',
      desc: '',
      args: [],
    );
  }

  /// `Subscribe podcast via search or import OPML file.`
  String get introSecondPage {
    return Intl.message(
      'Subscribe podcast via search or import OPML file.',
      name: 'introSecondPage',
      desc: '',
      args: [],
    );
  }

  /// `You can create new group for podcasts.`
  String get introThirdPage {
    return Intl.message(
      'You can create new group for podcasts.',
      name: 'introThirdPage',
      desc: '',
      args: [],
    );
  }

  /// `Invalid username`
  String get invalidName {
    return Intl.message(
      'Invalid username',
      name: 'invalidName',
      desc: '',
      args: [],
    );
  }

  /// `Google wants to control which apps you can install on your phone.`
  String get keepAndroidOpen {
    return Intl.message(
      'Google wants to control which apps you can install on your phone.',
      name: 'keepAndroidOpen',
      desc: '',
      args: [],
    );
  }

  /// `Learn more and make you voice heard on keepandroidopen.org.`
  String get keepAndroidOpenDes {
    return Intl.message(
      'Learn more and make you voice heard on keepandroidopen.org.',
      name: 'keepAndroidOpenDes',
      desc: '',
      args: [],
    );
  }

  /// `Last update`
  String get lastUpdate {
    return Intl.message(
      'Last update',
      name: 'lastUpdate',
      desc: 'gpodder.net update',
      args: [],
    );
  }

  /// `Later`
  String get later {
    return Intl.message(
      'Later',
      name: 'later',
      desc: '',
      args: [],
    );
  }

  /// `Light mode`
  String get lightMode {
    return Intl.message(
      'Light mode',
      name: 'lightMode',
      desc: '',
      args: [],
    );
  }

  /// `Like`
  String get like {
    return Intl.message(
      'Like',
      name: 'like',
      desc: '',
      args: [],
    );
  }

  /// `Liked`
  String get liked {
    return Intl.message(
      'Liked',
      name: 'liked',
      desc: '',
      args: [],
    );
  }

  /// `Like date`
  String get likeDate {
    return Intl.message(
      'Like date',
      name: 'likeDate',
      desc: 'Favorite tab, sort by like date.',
      args: [],
    );
  }

  /// `Listen`
  String get listen {
    return Intl.message(
      'Listen',
      name: 'listen',
      desc: '',
      args: [],
    );
  }

  /// `Listened`
  String get listened {
    return Intl.message(
      'Listened',
      name: 'listened',
      desc: '',
      args: [],
    );
  }

  /// `Local episode at {filePath}`
  String localEpisodeDescription(Object filePath) {
    return Intl.message(
      'Local episode at $filePath',
      name: 'localEpisodeDescription',
      desc: '',
      args: [filePath],
    );
  }

  /// `Local Folder`
  String get localFolder {
    return Intl.message(
      'Local Folder',
      name: 'localFolder',
      desc: 'Podcast name for episodes imported from audio files on device',
      args: [],
    );
  }

  /// `Dummy podcast that collects imported local audio files.`
  String get localFolderDescription {
    return Intl.message(
      'Dummy podcast that collects imported local audio files.',
      name: 'localFolderDescription',
      desc: '',
      args: [],
    );
  }

  /// `You can contribute to the localization of this app on hosted Weblate thanks to their support of open source projects.`
  String get localizationWeblate {
    return Intl.message(
      'You can contribute to the localization of this app on hosted Weblate thanks to their support of open source projects.',
      name: 'localizationWeblate',
      desc: '',
      args: [],
    );
  }

  /// `Load All Selected`
  String get loadAllSelected {
    return Intl.message(
      'Load All Selected',
      name: 'loadAllSelected',
      desc:
          'Tooltip for button that loads all episodes included in a selection.',
      args: [],
    );
  }

  /// `Loading`
  String get loading {
    return Intl.message(
      'Loading',
      name: 'loading',
      desc: '',
      args: [],
    );
  }

  /// `Load more`
  String get loadMore {
    return Intl.message(
      'Load more',
      name: 'loadMore',
      desc: '',
      args: [],
    );
  }

  /// `Logged in as {userName}`
  String loggedInAs(Object userName) {
    return Intl.message(
      'Logged in as $userName',
      name: 'loggedInAs',
      desc: 'gpodder.net',
      args: [userName],
    );
  }

  /// `Login`
  String get login {
    return Intl.message(
      'Login',
      name: 'login',
      desc: 'gpodder.net login',
      args: [],
    );
  }

  /// `Login failed`
  String get loginFailed {
    return Intl.message(
      'Login failed',
      name: 'loginFailed',
      desc: '',
      args: [],
    );
  }

  /// `Logout`
  String get logout {
    return Intl.message(
      'Logout',
      name: 'logout',
      desc: 'gpodder.net logout',
      args: [],
    );
  }

  /// `Mark`
  String get mark {
    return Intl.message(
      'Mark',
      name: 'mark',
      desc: 'In listen history page, if a episode is marked as listened.',
      args: [],
    );
  }

  /// `Confirm marking`
  String get markConfirm {
    return Intl.message(
      'Confirm marking',
      name: 'markConfirm',
      desc: '',
      args: [],
    );
  }

  /// `Confirm to mark all episodes as listened?`
  String get markConfirmContent {
    return Intl.message(
      'Confirm to mark all episodes as listened?',
      name: 'markConfirmContent',
      desc: '',
      args: [],
    );
  }

  /// `Mark as listened`
  String get markListened {
    return Intl.message(
      'Mark as listened',
      name: 'markListened',
      desc: '',
      args: [],
    );
  }

  /// `Mark not listened`
  String get markNotListened {
    return Intl.message(
      'Mark not listened',
      name: 'markNotListened',
      desc: '',
      args: [],
    );
  }

  /// `Menu`
  String get menu {
    return Intl.message(
      'Menu',
      name: 'menu',
      desc: '',
      args: [],
    );
  }

  /// `All podcasts`
  String get menuAllPodcasts {
    return Intl.message(
      'All podcasts',
      name: 'menuAllPodcasts',
      desc: '',
      args: [],
    );
  }

  /// `Mark All As Listened`
  String get menuMarkAllListened {
    return Intl.message(
      'Mark All As Listened',
      name: 'menuMarkAllListened',
      desc: '',
      args: [],
    );
  }

  /// `Visit RSS Feed`
  String get menuViewRSS {
    return Intl.message(
      'Visit RSS Feed',
      name: 'menuViewRSS',
      desc: '',
      args: [],
    );
  }

  /// `Visit Site`
  String get menuVisitSite {
    return Intl.message(
      'Visit Site',
      name: 'menuVisitSite',
      desc: '',
      args: [],
    );
  }

  /// `{count, plural, zero{Just now} one{{count} minute ago} other{{count} minutes ago}}`
  String minsAgo(num count) {
    return Intl.plural(
      count,
      zero: 'Just now',
      one: '$count minute ago',
      other: '$count minutes ago',
      name: 'minsAgo',
      desc: '',
      args: [count],
    );
  }

  /// `{count, plural, zero{0 min} one{{count} min} other{{count} mins}}`
  String minsCount(num count) {
    return Intl.plural(
      count,
      zero: '0 min',
      one: '$count min',
      other: '$count mins',
      name: 'minsCount',
      desc: '',
      args: [count],
    );
  }

  /// `Mobile Data`
  String get mobileData {
    return Intl.message(
      'Mobile Data',
      name: 'mobileData',
      desc: '',
      args: [],
    );
  }

  /// `{count, plural, zero{{count} months} one{{count} month} other{{count} months}}`
  String monthsCount(num count) {
    return Intl.plural(
      count,
      zero: '$count months',
      one: '$count month',
      other: '$count months',
      name: 'monthsCount',
      desc: '',
      args: [count],
    );
  }

  /// `More Options`
  String get moreOptions {
    return Intl.message(
      'More Options',
      name: 'moreOptions',
      desc: '',
      args: [],
    );
  }

  /// `Network`
  String get network {
    return Intl.message(
      'Network',
      name: 'network',
      desc: '',
      args: [],
    );
  }

  /// `Network error (DNS issue)`
  String get networkErrorDNS {
    return Intl.message(
      'Network error (DNS issue)',
      name: 'networkErrorDNS',
      desc: 'Notify the user that the host address couldn\'t be found.',
      args: [],
    );
  }

  /// `Don't include in global sync`
  String get neverAutoUpdate {
    return Intl.message(
      'Don\'t include in global sync',
      name: 'neverAutoUpdate',
      desc: '',
      args: [],
    );
  }

  /// `The podcast can still be synced on its own.`
  String get neverAutoUpdateDes {
    return Intl.message(
      'The podcast can still be synced on its own.',
      name: 'neverAutoUpdateDes',
      desc: '',
      args: [],
    );
  }

  /// `Newest first`
  String get newestFirst {
    return Intl.message(
      'Newest first',
      name: 'newestFirst',
      desc: '',
      args: [],
    );
  }

  /// `Create new group`
  String get newGroup {
    return Intl.message(
      'Create new group',
      name: 'newGroup',
      desc: '',
      args: [],
    );
  }

  /// `New`
  String get newPlain {
    return Intl.message(
      'New',
      name: 'newPlain',
      desc: 'Word to describe a new episode (and use in filterType)',
      args: [],
    );
  }

  /// `New Playlist`
  String get newPlaylist {
    return Intl.message(
      'New Playlist',
      name: 'newPlaylist',
      desc: '',
      args: [],
    );
  }

  /// `Next`
  String get next {
    return Intl.message(
      'Next',
      name: 'next',
      desc: '',
      args: [],
    );
  }

  /// `No episodes found with given filters`
  String get noEpisodesFound {
    return Intl.message(
      'No episodes found with given filters',
      name: 'noEpisodesFound',
      desc: '',
      args: [],
    );
  }

  /// `None`
  String get none {
    return Intl.message(
      'None',
      name: 'none',
      desc: 'Indicates that no option was selected among the given options.',
      args: [],
    );
  }

  /// `No podcasts in this group`
  String get noPodcastGroup {
    return Intl.message(
      'No podcasts in this group',
      name: 'noPodcastGroup',
      desc: '',
      args: [],
    );
  }

  /// `No show notes available for this episode.`
  String get noShownote {
    return Intl.message(
      'No show notes available for this episode.',
      name: 'noShownote',
      desc: 'Means this episode have no show notes.',
      args: [],
    );
  }

  /// `Fetch data {title}`
  String notificaitonFatch(Object title) {
    return Intl.message(
      'Fetch data $title',
      name: 'notificaitonFatch',
      desc: '',
      args: [title],
    );
  }

  /// `Adding and organizing groups.`
  String get notificationAddingGroups {
    return Intl.message(
      'Adding and organizing groups.',
      name: 'notificationAddingGroups',
      desc: '',
      args: [],
    );
  }

  /// `Subscribing failed, network error {title}`
  String notificationNetworkError(Object title) {
    return Intl.message(
      'Subscribing failed, network error $title',
      name: 'notificationNetworkError',
      desc: '',
      args: [title],
    );
  }

  /// `Subscribe {title}`
  String notificationSubscribe(Object title) {
    return Intl.message(
      'Subscribe $title',
      name: 'notificationSubscribe',
      desc: '',
      args: [title],
    );
  }

  /// `Subscribing to podcasts.`
  String get notificationSubscribing {
    return Intl.message(
      'Subscribing to podcasts.',
      name: 'notificationSubscribing',
      desc: '',
      args: [],
    );
  }

  /// `Subscribing failed, podcast already exists {title}`
  String notificationSubscribeExisted(Object title) {
    return Intl.message(
      'Subscribing failed, podcast already exists $title',
      name: 'notificationSubscribeExisted',
      desc: '',
      args: [title],
    );
  }

  /// `Subscribed successfully {title}`
  String notificationSuccess(Object title) {
    return Intl.message(
      'Subscribed successfully $title',
      name: 'notificationSuccess',
      desc: '',
      args: [title],
    );
  }

  /// `Update {title}`
  String notificationUpdate(Object title) {
    return Intl.message(
      'Update $title',
      name: 'notificationUpdate',
      desc: '',
      args: [title],
    );
  }

  /// `Update error {title}`
  String notificationUpdateError(Object title) {
    return Intl.message(
      'Update error $title',
      name: 'notificationUpdateError',
      desc: '',
      args: [title],
    );
  }

  /// `Oldest first`
  String get oldestFirst {
    return Intl.message(
      'Oldest first',
      name: 'oldestFirst',
      desc: '',
      args: [],
    );
  }

  /// `OPML file`
  String get opmlFile {
    return Intl.message(
      'OPML file',
      name: 'opmlFile',
      desc: '',
      args: [],
    );
  }

  /// `Password required`
  String get passwdRequired {
    return Intl.message(
      'Password required',
      name: 'passwdRequired',
      desc: '',
      args: [],
    );
  }

  /// `Password`
  String get password {
    return Intl.message(
      'Password',
      name: 'password',
      desc: '',
      args: [],
    );
  }

  /// `Pause`
  String get pause {
    return Intl.message(
      'Pause',
      name: 'pause',
      desc: '',
      args: [],
    );
  }

  /// `Play`
  String get play {
    return Intl.message(
      'Play',
      name: 'play',
      desc: '',
      args: [],
    );
  }

  /// `Playback control`
  String get playback {
    return Intl.message(
      'Playback control',
      name: 'playback',
      desc: '',
      args: [],
    );
  }

  /// `Player`
  String get player {
    return Intl.message(
      'Player',
      name: 'player',
      desc: '',
      args: [],
    );
  }

  /// `Medium`
  String get playerHeightMed {
    return Intl.message(
      'Medium',
      name: 'playerHeightMed',
      desc: '',
      args: [],
    );
  }

  /// `Low`
  String get playerHeightShort {
    return Intl.message(
      'Low',
      name: 'playerHeightShort',
      desc: '',
      args: [],
    );
  }

  /// `High`
  String get playerHeightTall {
    return Intl.message(
      'High',
      name: 'playerHeightTall',
      desc: '',
      args: [],
    );
  }

  /// `Playing`
  String get playing {
    return Intl.message(
      'Playing',
      name: 'playing',
      desc: '',
      args: [],
    );
  }

  /// `Playlist already exists`
  String get playlistExists {
    return Intl.message(
      'Playlist already exists',
      name: 'playlistExists',
      desc: '',
      args: [],
    );
  }

  /// `Playlist name is empty`
  String get playlistNameEmpty {
    return Intl.message(
      'Playlist name is empty',
      name: 'playlistNameEmpty',
      desc: 'Error string when creating new playlist.',
      args: [],
    );
  }

  /// `Playlists`
  String get playlists {
    return Intl.message(
      'Playlists',
      name: 'playlists',
      desc: 'Title for playlists tab.',
      args: [],
    );
  }

  /// `Play next`
  String get playNext {
    return Intl.message(
      'Play next',
      name: 'playNext',
      desc: 'Popup menu for episode.',
      args: [],
    );
  }

  /// `Add episode to top of the playlist`
  String get playNextDes {
    return Intl.message(
      'Add episode to top of the playlist',
      name: 'playNextDes',
      desc: 'Description for next play.',
      args: [],
    );
  }

  /// `Plugins`
  String get plugins {
    return Intl.message(
      'Plugins',
      name: 'plugins',
      desc: '',
      args: [],
    );
  }

  /// `{count, plural, zero{} one{Podcast} other{Podcasts}}`
  String podcast(num count) {
    return Intl.plural(
      count,
      zero: '',
      one: 'Podcast',
      other: 'Podcasts',
      name: 'podcast',
      desc: '',
      args: [count],
    );
  }

  /// `Podcast List`
  String get podcastList {
    return Intl.message(
      'Podcast List',
      name: 'podcastList',
      desc: '',
      args: [],
    );
  }

  /// `Podcast subscribed`
  String get podcastSubscribed {
    return Intl.message(
      'Podcast subscribed',
      name: 'podcastSubscribed',
      desc: '',
      args: [],
    );
  }

  /// `Download episode`
  String get popupMenuDownloadDes {
    return Intl.message(
      'Download episode',
      name: 'popupMenuDownloadDes',
      desc: '',
      args: [],
    );
  }

  /// `Add episode to playlist`
  String get popupMenuLaterDes {
    return Intl.message(
      'Add episode to playlist',
      name: 'popupMenuLaterDes',
      desc: '',
      args: [],
    );
  }

  /// `Add episode to favorite`
  String get popupMenuLikeDes {
    return Intl.message(
      'Add episode to favorite',
      name: 'popupMenuLikeDes',
      desc: '',
      args: [],
    );
  }

  /// `Mark episode as listened to`
  String get popupMenuMarkDes {
    return Intl.message(
      'Mark episode as listened to',
      name: 'popupMenuMarkDes',
      desc: '',
      args: [],
    );
  }

  /// `Play the episode`
  String get popupMenuPlayDes {
    return Intl.message(
      'Play the episode',
      name: 'popupMenuPlayDes',
      desc: '',
      args: [],
    );
  }

  /// `Privacy Policy`
  String get privacyPolicy {
    return Intl.message(
      'Privacy Policy',
      name: 'privacyPolicy',
      desc: '',
      args: [],
    );
  }

  /// `Publish Date`
  String get publishDate {
    return Intl.message(
      'Publish Date',
      name: 'publishDate',
      desc: 'Publish Date sort order',
      args: [],
    );
  }

  /// `Published at {date}`
  String published(Object date) {
    return Intl.message(
      'Published at $date',
      name: 'published',
      desc: '',
      args: [date],
    );
  }

  /// `Published daily`
  String get publishedDaily {
    return Intl.message(
      'Published daily',
      name: 'publishedDaily',
      desc: '',
      args: [],
    );
  }

  /// `Published monthly`
  String get publishedMonthly {
    return Intl.message(
      'Published monthly',
      name: 'publishedMonthly',
      desc: '',
      args: [],
    );
  }

  /// `Published weekly`
  String get publishedWeekly {
    return Intl.message(
      'Published weekly',
      name: 'publishedWeekly',
      desc: 'In search podcast detail page.',
      args: [],
    );
  }

  /// `Published yearly`
  String get publishedYearly {
    return Intl.message(
      'Published yearly',
      name: 'publishedYearly',
      desc: '',
      args: [],
    );
  }

  /// `Queue`
  String get queue {
    return Intl.message(
      'Queue',
      name: 'queue',
      desc: 'Queue',
      args: [],
    );
  }

  /// `Random`
  String get random {
    return Intl.message(
      'Random',
      name: 'random',
      desc: 'Random sort order',
      args: [],
    );
  }

  /// `Recover subscribe`
  String get recoverSubscribe {
    return Intl.message(
      'Recover subscribe',
      name: 'recoverSubscribe',
      desc:
          'User can recover subscribe podcast after remove it in subscribe history page.',
      args: [],
    );
  }

  /// `Refresh`
  String get refresh {
    return Intl.message(
      'Refresh',
      name: 'refresh',
      desc: 'Refresh',
      args: [],
    );
  }

  /// `Update artwork`
  String get refreshArtwork {
    return Intl.message(
      'Update artwork',
      name: 'refreshArtwork',
      desc: '',
      args: [],
    );
  }

  /// `Remove`
  String get remove {
    return Intl.message(
      'Remove',
      name: 'remove',
      desc: 'Remove not "removed". \nRemove a podcast or a group.',
      args: [],
    );
  }

  /// `Removal confirmation`
  String get removeConfirm {
    return Intl.message(
      'Removal confirmation',
      name: 'removeConfirm',
      desc: 'unsubscribe podcast dialog',
      args: [],
    );
  }

  /// `Removed at {date}`
  String removedAt(Object date) {
    return Intl.message(
      'Removed at $date',
      name: 'removedAt',
      desc: 'For example ：Removed at 2020.10.10',
      args: [date],
    );
  }

  /// `Remove Download`
  String get removeDownload {
    return Intl.message(
      'Remove Download',
      name: 'removeDownload',
      desc: '',
      args: [],
    );
  }

  /// `Remove new mark`
  String get removeNewMark {
    return Intl.message(
      'Remove new mark',
      name: 'removeNewMark',
      desc: 'Remove new mark for new episodes.',
      args: [],
    );
  }

  /// `Are you sure you want to unsubscribe?`
  String get removePodcastDes {
    return Intl.message(
      'Are you sure you want to unsubscribe?',
      name: 'removePodcastDes',
      desc: '',
      args: [],
    );
  }

  /// `Restart the app for the changes to take effect.`
  String get restartAppForEffect {
    return Intl.message(
      'Restart the app for the changes to take effect.',
      name: 'restartAppForEffect',
      desc: 'Notify user that the change will take effect after app restart.',
      args: [],
    );
  }

  /// `Satellite`
  String get satellite {
    return Intl.message(
      'Satellite',
      name: 'satellite',
      desc: '',
      args: [],
    );
  }

  /// `Save`
  String get save {
    return Intl.message(
      'Save',
      name: 'save',
      desc: '',
      args: [],
    );
  }

  /// `Schedule`
  String get schedule {
    return Intl.message(
      'Schedule',
      name: 'schedule',
      desc: '',
      args: [],
    );
  }

  /// `Schedule disabled.`
  String get scheduleDisabled {
    return Intl.message(
      'Schedule disabled.',
      name: 'scheduleDisabled',
      desc: '',
      args: [],
    );
  }

  /// `Schedule: {start} - {end}`
  String scheduleTime(Object start, Object end) {
    return Intl.message(
      'Schedule: $start - $end',
      name: 'scheduleTime',
      desc: 'For example \'Schedule: 21:50 - 06:30\'',
      args: [start, end],
    );
  }

  /// `Search`
  String get search {
    return Intl.message(
      'Search',
      name: 'search',
      desc: '',
      args: [],
    );
  }

  /// `Search Api`
  String get searchApi {
    return Intl.message(
      'Search Api',
      name: 'searchApi',
      desc: '',
      args: [],
    );
  }

  /// `Search Engine`
  String get searchEngine {
    return Intl.message(
      'Search Engine',
      name: 'searchEngine',
      desc: '',
      args: [],
    );
  }

  /// `Search episode`
  String get searchEpisode {
    return Intl.message(
      'Search episode',
      name: 'searchEpisode',
      desc: '',
      args: [],
    );
  }

  /// `Type the podcast name, keywords or enter a feed url.`
  String get searchHelper {
    return Intl.message(
      'Type the podcast name, keywords or enter a feed url.',
      name: 'searchHelper',
      desc: '',
      args: [],
    );
  }

  /// `Enter an rss feed url or search for a podcast and open its rss feed to subscribe.`
  String get searchInstructions {
    return Intl.message(
      'Enter an rss feed url or search for a podcast and open its rss feed to subscribe.',
      name: 'searchInstructions',
      desc: '',
      args: [],
    );
  }

  /// `Invalid RSS link`
  String get searchInvalidRss {
    return Intl.message(
      'Invalid RSS link',
      name: 'searchInvalidRss',
      desc: '',
      args: [],
    );
  }

  /// `Search for podcasts`
  String get searchPodcast {
    return Intl.message(
      'Search for podcasts',
      name: 'searchPodcast',
      desc: '',
      args: [],
    );
  }

  /// `Web Search`
  String get searchWeb {
    return Intl.message(
      'Web Search',
      name: 'searchWeb',
      desc: '',
      args: [],
    );
  }

  /// `{count, plural, zero{0 sec} one{{count} sec} other{{count} sec}}`
  String secCount(num count) {
    return Intl.plural(
      count,
      zero: '0 sec',
      one: '$count sec',
      other: '$count sec',
      name: 'secCount',
      desc: '',
      args: [count],
    );
  }

  /// `{count, plural, zero{Just now} one{{count} second ago} other{{count} seconds ago}}`
  String secondsAgo(num count) {
    return Intl.plural(
      count,
      zero: 'Just now',
      one: '$count second ago',
      other: '$count seconds ago',
      name: 'secondsAgo',
      desc: '',
      args: [count],
    );
  }

  /// `{count} selected`
  String selected(Object count) {
    return Intl.message(
      '$count selected',
      name: 'selected',
      desc: '',
      args: [count],
    );
  }

  /// `Selection Mode`
  String get selectMode {
    return Intl.message(
      'Selection Mode',
      name: 'selectMode',
      desc: '',
      args: [],
    );
  }

  /// `Settings`
  String get settings {
    return Intl.message(
      'Settings',
      name: 'settings',
      desc: '',
      args: [],
    );
  }

  /// `Accent color`
  String get settingsAccentColor {
    return Intl.message(
      'Accent color',
      name: 'settingsAccentColor',
      desc: '',
      args: [],
    );
  }

  /// `Appearance`
  String get settingsAppearance {
    return Intl.message(
      'Appearance',
      name: 'settingsAppearance',
      desc: '',
      args: [],
    );
  }

  /// `Colors and themes`
  String get settingsAppearanceDes {
    return Intl.message(
      'Colors and themes',
      name: 'settingsAppearanceDes',
      desc: '',
      args: [],
    );
  }

  /// `App Intro`
  String get settingsAppIntro {
    return Intl.message(
      'App Intro',
      name: 'settingsAppIntro',
      desc: '',
      args: [],
    );
  }

  /// `Audio cache`
  String get settingsAudioCache {
    return Intl.message(
      'Audio cache',
      name: 'settingsAudioCache',
      desc: '',
      args: [],
    );
  }

  /// `Audio cache max size`
  String get settingsAudioCacheDes {
    return Intl.message(
      'Audio cache max size',
      name: 'settingsAudioCacheDes',
      desc: '',
      args: [],
    );
  }

  /// `Auto delete`
  String get settingsAutoDelete {
    return Intl.message(
      'Auto delete',
      name: 'settingsAutoDelete',
      desc: '',
      args: [],
    );
  }

  /// `Deletions are performed on app start and on sync.`
  String get settingsAutoDeleteDes {
    return Intl.message(
      'Deletions are performed on app start and on sync.',
      name: 'settingsAutoDeleteDes',
      desc: '',
      args: [],
    );
  }

  /// `Delete old downloads`
  String get settingsAutoDeleteAfterTime {
    return Intl.message(
      'Delete old downloads',
      name: 'settingsAutoDeleteAfterTime',
      desc: 'Settings item, displayed alongide a day count picker.',
      args: [],
    );
  }

  /// `Delete downloads older than...`
  String get settingsAutoDeleteAfterTimeDes {
    return Intl.message(
      'Delete downloads older than...',
      name: 'settingsAutoDeleteAfterTimeDes',
      desc: 'Settings item, displayed alongide a day count picker.',
      args: [],
    );
  }

  /// `Delete played downloads`
  String get settingsAutoDeleteAfterPlayed {
    return Intl.message(
      'Delete played downloads',
      name: 'settingsAutoDeleteAfterPlayed',
      desc: '',
      args: [],
    );
  }

  /// `Limit downloads storage`
  String get settingsAutoDeleteOldestIfTotalAbove {
    return Intl.message(
      'Limit downloads storage',
      name: 'settingsAutoDeleteOldestIfTotalAbove',
      desc:
          'Settings item, displayed alongside a storage size picker. (in 100 MiBs)',
      args: [],
    );
  }

  /// `If total size of audio downloads exceeds this, the oldest downloads will be deleted.`
  String get settingsAutoDeleteOldestIfTotalAboveDes {
    return Intl.message(
      'If total size of audio downloads exceeds this, the oldest downloads will be deleted.',
      name: 'settingsAutoDeleteOldestIfTotalAboveDes',
      desc: '',
      args: [],
    );
  }

  /// `Global auto download`
  String get settingsAutoDownload {
    return Intl.message(
      'Global auto download',
      name: 'settingsAutoDownload',
      desc: '',
      args: [],
    );
  }

  /// `Download episodes marked new after sync if the podcast has auto download turned on.`
  String get settingsAutoDownloadDes {
    return Intl.message(
      'Download episodes marked new after sync if the podcast has auto download turned on.',
      name: 'settingsAutoDownloadDes',
      desc: '',
      args: [],
    );
  }

  /// `Default auto download`
  String get settingsAutoDownloadNewPodcast {
    return Intl.message(
      'Default auto download',
      name: 'settingsAutoDownloadNewPodcast',
      desc: '',
      args: [],
    );
  }

  /// `Auto download setting value for newly subscribed podcasts.`
  String get settingsAutoDownloadNewPodcastDes {
    return Intl.message(
      'Auto download setting value for newly subscribed podcasts.',
      name: 'settingsAutoDownloadNewPodcastDes',
      desc: '',
      args: [],
    );
  }

  /// `Auto download on forbidden connections`
  String get settingsAutoDownloadOnForbidden {
    return Intl.message(
      'Auto download on forbidden connections',
      name: 'settingsAutoDownloadOnForbidden',
      desc: '',
      args: [],
    );
  }

  /// `If disabled, auto downloads starting on forbidden connections will be immediately paused.`
  String get settingsAutoDownloadOnForbiddenDes {
    return Intl.message(
      'If disabled, auto downloads starting on forbidden connections will be immediately paused.',
      name: 'settingsAutoDownloadOnForbiddenDes',
      desc: '',
      args: [],
    );
  }

  /// `Auto play the next episode when an episode ends.`
  String get settingsAutoPlayDes {
    return Intl.message(
      'Auto play the next episode when an episode ends.',
      name: 'settingsAutoPlayDes',
      desc: '',
      args: [],
    );
  }

  /// `Auto synchronisation`
  String get settingsAutoSync {
    return Intl.message(
      'Auto synchronisation',
      name: 'settingsAutoSync',
      desc: '',
      args: [],
    );
  }

  /// `Periodically refresh all podcasts in the background to get the latest episodes.`
  String get settingsAutoSyncDes {
    return Intl.message(
      'Periodically refresh all podcasts in the background to get the latest episodes.',
      name: 'settingsAutoSyncDes',
      desc: '',
      args: [],
    );
  }

  /// `Backup`
  String get settingsBackup {
    return Intl.message(
      'Backup',
      name: 'settingsBackup',
      desc: '',
      args: [],
    );
  }

  /// `Backup, restore or reset`
  String get settingsBackupDes {
    return Intl.message(
      'Backup, restore or reset',
      name: 'settingsBackupDes',
      desc: '',
      args: [],
    );
  }

  /// `Categories`
  String get settingsBackupCategories {
    return Intl.message(
      'Categories',
      name: 'settingsBackupCategories',
      desc: '',
      args: [],
    );
  }

  /// `Settings categories to export, import or reset.`
  String get settingsBackupCategoriesDes {
    return Intl.message(
      'Settings categories to export, import or reset.',
      name: 'settingsBackupCategoriesDes',
      desc: '',
      args: [],
    );
  }

  /// `Settings categories to import.`
  String get settingsBackupCategoriesImportDes {
    return Intl.message(
      'Settings categories to import.',
      name: 'settingsBackupCategoriesImportDes',
      desc: '',
      args: [],
    );
  }

  /// `Are you sure you want to wipe the selected database categories and replace them with the backup?`
  String get settingsBackupConfirmationDatabaseOverwrite {
    return Intl.message(
      'Are you sure you want to wipe the selected database categories and replace them with the backup?',
      name: 'settingsBackupConfirmationDatabaseOverwrite',
      desc: '',
      args: [],
    );
  }

  /// `Are you sure you want to reset the selected database categories?`
  String get settingsBackupConfirmationDatabaseReset {
    return Intl.message(
      'Are you sure you want to reset the selected database categories?',
      name: 'settingsBackupConfirmationDatabaseReset',
      desc: '',
      args: [],
    );
  }

  /// `Are you sure you want to overwrite the current settings in the selected categories?`
  String get settingsBackupConfirmationSettingsOverwrite {
    return Intl.message(
      'Are you sure you want to overwrite the current settings in the selected categories?',
      name: 'settingsBackupConfirmationSettingsOverwrite',
      desc: '',
      args: [],
    );
  }

  /// `Are you sure you want to reset settings in the selected categories to default?`
  String get settingsBackupConfirmationSettingsReset {
    return Intl.message(
      'Are you sure you want to reset settings in the selected categories to default?',
      name: 'settingsBackupConfirmationSettingsReset',
      desc: '',
      args: [],
    );
  }

  /// `Database`
  String get settingsBackupDatabase {
    return Intl.message(
      'Database',
      name: 'settingsBackupDatabase',
      desc: '',
      args: [],
    );
  }

  /// `Database file`
  String get settingsBackupDatabaseBackupFile {
    return Intl.message(
      'Database file',
      name: 'settingsBackupDatabaseBackupFile',
      desc: '',
      args: [],
    );
  }

  /// `Export, import and reset app data.`
  String get settingsBackupDatabaseBackupFileDes {
    return Intl.message(
      'Export, import and reset app data.',
      name: 'settingsBackupDatabaseBackupFileDes',
      desc: '',
      args: [],
    );
  }

  /// `Database categories to export, import or reset.`
  String get settingsBackupDatabaseCategoriesDes {
    return Intl.message(
      'Database categories to export, import or reset.',
      name: 'settingsBackupDatabaseCategoriesDes',
      desc: '',
      args: [],
    );
  }

  /// `Podcasts, episodes and groups`
  String get settingsBackupDatabasePodcasts {
    return Intl.message(
      'Podcasts, episodes and groups',
      name: 'settingsBackupDatabasePodcasts',
      desc: '',
      args: [],
    );
  }

  /// `Playback and subscription history`
  String get settingsBackupDatabaseHistory {
    return Intl.message(
      'Playback and subscription history',
      name: 'settingsBackupDatabaseHistory',
      desc: '',
      args: [],
    );
  }

  /// `Playlists`
  String get settingsBackupDatabasePlaylists {
    return Intl.message(
      'Playlists',
      name: 'settingsBackupDatabasePlaylists',
      desc: '',
      args: [],
    );
  }

  /// `Settings Backup File`
  String get settingsBackupFile {
    return Intl.message(
      'Settings Backup File',
      name: 'settingsBackupFile',
      desc: '',
      args: [],
    );
  }

  /// `Legacy Settings Backup File`
  String get settingsBackupLegacyFile {
    return Intl.message(
      'Legacy Settings Backup File',
      name: 'settingsBackupLegacyFile',
      desc: '',
      args: [],
    );
  }

  /// `Import backups created before v0.10.`
  String get settingsBackupLegacyFileDes {
    return Intl.message(
      'Import backups created before v0.10.',
      name: 'settingsBackupLegacyFileDes',
      desc: '',
      args: [],
    );
  }

  /// `Backup Password`
  String get settingsBackupPassword {
    return Intl.message(
      'Backup Password',
      name: 'settingsBackupPassword',
      desc: '',
      args: [],
    );
  }

  /// `Optional password to encrypt the backup when exporting or decrypt it when importing.`
  String get settingsBackupPasswordDes {
    return Intl.message(
      'Optional password to encrypt the backup when exporting or decrypt it when importing.',
      name: 'settingsBackupPasswordDes',
      desc: '',
      args: [],
    );
  }

  /// `Volume boost amount`
  String get settingsBoostVolume {
    return Intl.message(
      'Volume boost amount',
      name: 'settingsBoostVolume',
      desc: '',
      args: [],
    );
  }

  /// `Decibels to boost by when volume boost is enabled.`
  String get settingsBoostVolumeDes {
    return Intl.message(
      'Decibels to boost by when volume boost is enabled.',
      name: 'settingsBoostVolumeDes',
      desc: '',
      args: [],
    );
  }

  /// `Colors`
  String get settingsColors {
    return Intl.message(
      'Colors',
      name: 'settingsColors',
      desc: '',
      args: [],
    );
  }

  /// `Default Filters`
  String get settingsDefaultFilters {
    return Intl.message(
      'Default Filters',
      name: 'settingsDefaultFilters',
      desc: '',
      args: [],
    );
  }

  /// `Android Auto Filters`
  String get settingsDefaultFilterAndroidAuto {
    return Intl.message(
      'Android Auto Filters',
      name: 'settingsDefaultFilterAndroidAuto',
      desc: '',
      args: [],
    );
  }

  /// `Filters to apply to the library visible in Android Auto. Only the first 108 items will be shown.`
  String get settingsDefaultFilterAndroidAutoDes {
    return Intl.message(
      'Filters to apply to the library visible in Android Auto. Only the first 108 items will be shown.',
      name: 'settingsDefaultFilterAndroidAutoDes',
      desc: '',
      args: [],
    );
  }

  /// `Default grid view`
  String get settingsDefaultGrid {
    return Intl.message(
      'Default grid view',
      name: 'settingsDefaultGrid',
      desc: '',
      args: [],
    );
  }

  /// `Download tab`
  String get settingsDefaultGridDownload {
    return Intl.message(
      'Download tab',
      name: 'settingsDefaultGridDownload',
      desc: '',
      args: [],
    );
  }

  /// `Favorites tab`
  String get settingsDefaultGridFavorite {
    return Intl.message(
      'Favorites tab',
      name: 'settingsDefaultGridFavorite',
      desc: '',
      args: [],
    );
  }

  /// `Podcast page`
  String get settingsDefaultGridPodcast {
    return Intl.message(
      'Podcast page',
      name: 'settingsDefaultGridPodcast',
      desc: '',
      args: [],
    );
  }

  /// `Recent tab`
  String get settingsDefaultGridRecent {
    return Intl.message(
      'Recent tab',
      name: 'settingsDefaultGridRecent',
      desc: '',
      args: [],
    );
  }

  /// `Reenable "Discover Features"`
  String get settingsDiscovery {
    return Intl.message(
      'Reenable "Discover Features"',
      name: 'settingsDiscovery',
      desc:
          'Reset feature discovery state. User tap it and restart app, will see features tutorial again.',
      args: [],
    );
  }

  /// `Are you sure you want to reenable "Discover Features"?`
  String get settingsDiscoveryDes {
    return Intl.message(
      'Are you sure you want to reenable "Discover Features"?',
      name: 'settingsDiscoveryDes',
      desc: '',
      args: [],
    );
  }

  /// `Ask when starting download on a forbidden connection`
  String get settingsDownloadAskOnForbidden {
    return Intl.message(
      'Ask when starting download on a forbidden connection',
      name: 'settingsDownloadAskOnForbidden',
      desc: '',
      args: [],
    );
  }

  /// `If not approved, the download will not be started.`
  String get settingsDownloadAskOnForbiddenDes {
    return Intl.message(
      'If not approved, the download will not be started.',
      name: 'settingsDownloadAskOnForbiddenDes',
      desc: '',
      args: [],
    );
  }

  /// `Downloads`
  String get settingsDownloads {
    return Intl.message(
      'Downloads',
      name: 'settingsDownloads',
      desc: '',
      args: [],
    );
  }

  /// `Auto download, auto delete and forbidden connections`
  String get settingsDownloadsDes {
    return Intl.message(
      'Auto download, auto delete and forbidden connections',
      name: 'settingsDownloadsDes',
      desc: '',
      args: [],
    );
  }

  /// `Download position`
  String get settingsDownloadPosition {
    return Intl.message(
      'Download position',
      name: 'settingsDownloadPosition',
      desc: 'Choose folder for downloads.',
      args: [],
    );
  }

  /// `Episode Management`
  String get settingsEpisodeManagement {
    return Intl.message(
      'Episode Management',
      name: 'settingsEpisodeManagement',
      desc: '',
      args: [],
    );
  }

  /// `Export, import and reset app settings.`
  String get settingsExportDes {
    return Intl.message(
      'Export, import and reset app settings.',
      name: 'settingsExportDes',
      desc: '',
      args: [],
    );
  }

  /// `Fast forward seconds`
  String get settingsFastForwardSec {
    return Intl.message(
      'Fast forward seconds',
      name: 'settingsFastForwardSec',
      desc: '',
      args: [],
    );
  }

  /// `Change the fast forward seconds in player`
  String get settingsFastForwardSecDes {
    return Intl.message(
      'Change the fast forward seconds in player',
      name: 'settingsFastForwardSecDes',
      desc: '',
      args: [],
    );
  }

  /// `Feedback`
  String get settingsFeedback {
    return Intl.message(
      'Feedback',
      name: 'settingsFeedback',
      desc: '',
      args: [],
    );
  }

  /// `Bugs and feature requests`
  String get settingsFeedbackDes {
    return Intl.message(
      'Bugs and feature requests',
      name: 'settingsFeedbackDes',
      desc: '',
      args: [],
    );
  }

  /// `Forbidden download connections`
  String get settingsForbiddenDownloadConnections {
    return Intl.message(
      'Forbidden download connections',
      name: 'settingsForbiddenDownloadConnections',
      desc: '',
      args: [],
    );
  }

  /// `Downloads will be forbidden on selected connections based on the rules above.`
  String get settingsForbiddenDownloadConnectionsDes {
    return Intl.message(
      'Downloads will be forbidden on selected connections based on the rules above.',
      name: 'settingsForbiddenDownloadConnectionsDes',
      desc: '',
      args: [],
    );
  }

  /// `Full stop`
  String get settingsFullStop {
    return Intl.message(
      'Full stop',
      name: 'settingsFullStop',
      desc: '',
      args: [],
    );
  }

  /// `Kill the app when stop is pressed.`
  String get settingsFullStopDes {
    return Intl.message(
      'Kill the app when stop is pressed.',
      name: 'settingsFullStopDes',
      desc: '',
      args: [],
    );
  }

  /// `General`
  String get settingsGeneral {
    return Intl.message(
      'General',
      name: 'settingsGeneral',
      desc: '',
      args: [],
    );
  }

  /// `History`
  String get settingsHistory {
    return Intl.message(
      'History',
      name: 'settingsHistory',
      desc: '',
      args: [],
    );
  }

  /// `Listen data`
  String get settingsHistoryDes {
    return Intl.message(
      'Listen data',
      name: 'settingsHistoryDes',
      desc: '',
      args: [],
    );
  }

  /// `Home tabs`
  String get settingsHomeTabs {
    return Intl.message(
      'Home tabs',
      name: 'settingsHomeTabs',
      desc: '',
      args: [],
    );
  }

  /// `Tab name`
  String get settingsHomeTabName {
    return Intl.message(
      'Tab name',
      name: 'settingsHomeTabName',
      desc: '',
      args: [],
    );
  }

  /// `New tab`
  String get settingsHomeTabNew {
    return Intl.message(
      'New tab',
      name: 'settingsHomeTabNew',
      desc: '',
      args: [],
    );
  }

  /// `Add new tab`
  String get settingsHomeTabAdd {
    return Intl.message(
      'Add new tab',
      name: 'settingsHomeTabAdd',
      desc: '',
      args: [],
    );
  }

  /// `Info`
  String get settingsInfo {
    return Intl.message(
      'Info',
      name: 'settingsInfo',
      desc: '',
      args: [],
    );
  }

  /// `Interface`
  String get settingsInterface {
    return Intl.message(
      'Interface',
      name: 'settingsInterface',
      desc: '',
      args: [],
    );
  }

  /// `Ui defaults`
  String get settingsInterfaceDes {
    return Intl.message(
      'Ui defaults',
      name: 'settingsInterfaceDes',
      desc: '',
      args: [],
    );
  }

  /// `Language`
  String get settingsLanguage {
    return Intl.message(
      'Language',
      name: 'settingsLanguage',
      desc: '',
      args: [],
    );
  }

  /// `Settings (Legacy)`
  String get settingsLegacy {
    return Intl.message(
      'Settings (Legacy)',
      name: 'settingsLegacy',
      desc: '',
      args: [],
    );
  }

  /// `Libraries`
  String get settingsLibraries {
    return Intl.message(
      'Libraries',
      name: 'settingsLibraries',
      desc: '',
      args: [],
    );
  }

  /// `Open source libraries used in this app`
  String get settingsLibrariesDes {
    return Intl.message(
      'Open source libraries used in this app',
      name: 'settingsLibrariesDes',
      desc: '',
      args: [],
    );
  }

  /// `Look and Feel`
  String get settingsLookAndFeel {
    return Intl.message(
      'Look and Feel',
      name: 'settingsLookAndFeel',
      desc: '',
      args: [],
    );
  }

  /// `Colors, fonts and haptics`
  String get settingsLookAndFeelDes {
    return Intl.message(
      'Colors, fonts and haptics',
      name: 'settingsLookAndFeelDes',
      desc: '',
      args: [],
    );
  }

  /// `Manage downloads`
  String get settingsManageDownload {
    return Intl.message(
      'Manage downloads',
      name: 'settingsManageDownload',
      desc: '',
      args: [],
    );
  }

  /// `Manage downloaded audio files`
  String get settingsManageDownloadDes {
    return Intl.message(
      'Manage downloaded audio files',
      name: 'settingsManageDownloadDes',
      desc: '',
      args: [],
    );
  }

  /// `Manufacturer layout override`
  String get settingsManufacturerLayoutOverride {
    return Intl.message(
      'Manufacturer layout override',
      name: 'settingsManufacturerLayoutOverride',
      desc: '',
      args: [],
    );
  }

  /// `Mark skipped as played`
  String get settingsMarkListenedSkip {
    return Intl.message(
      'Mark skipped as played',
      name: 'settingsMarkListenedSkip',
      desc: '',
      args: [],
    );
  }

  /// `Mark episode as played when skipping to next.`
  String get settingsMarkListenedSkipDes {
    return Intl.message(
      'Mark episode as played when skipping to next.',
      name: 'settingsMarkListenedSkipDes',
      desc: '',
      args: [],
    );
  }

  /// `Notification panel media controls`
  String get settingsMediaControls {
    return Intl.message(
      'Notification panel media controls',
      name: 'settingsMediaControls',
      desc: '',
      args: [],
    );
  }

  /// `The placement of the buttons may differ between Android distributions, versions and selections of buttons.`
  String get settingsMediaControlsDes {
    return Intl.message(
      'The placement of the buttons may differ between Android distributions, versions and selections of buttons.',
      name: 'settingsMediaControlsDes',
      desc: '',
      args: [],
    );
  }

  /// `Auto play next`
  String get settingsMenuAutoPlay {
    return Intl.message(
      'Auto play next',
      name: 'settingsMenuAutoPlay',
      desc: '',
      args: [],
    );
  }

  /// `Ask before using cellular data`
  String get settingsNetworkCellular {
    return Intl.message(
      'Ask before using cellular data',
      name: 'settingsNetworkCellular',
      desc: '',
      args: [],
    );
  }

  /// `Ask to confirm when using cellular data to download episodes`
  String get settingsNetworkCellularDes {
    return Intl.message(
      'Ask to confirm when using cellular data to download episodes',
      name: 'settingsNetworkCellularDes',
      desc: '',
      args: [],
    );
  }

  /// `New Episodes`
  String get settingsNewEpisodes {
    return Intl.message(
      'New Episodes',
      name: 'settingsNewEpisodes',
      desc: '',
      args: [],
    );
  }

  /// `New episode criteria.`
  String get settingsNewEpisodesDes {
    return Intl.message(
      'New episode criteria.',
      name: 'settingsNewEpisodesDes',
      desc: '',
      args: [],
    );
  }

  /// `Mark new episodes`
  String get settingsNewEpisodesMark {
    return Intl.message(
      'Mark new episodes',
      name: 'settingsNewEpisodesMark',
      desc: '',
      args: [],
    );
  }

  /// `Maximum Age`
  String get settingsNewEpisodesMarkAge {
    return Intl.message(
      'Maximum Age',
      name: 'settingsNewEpisodesMarkAge',
      desc: '',
      args: [],
    );
  }

  /// `Publish date is newer than...`
  String get settingsNewEpisodesMarkAgeDes {
    return Intl.message(
      'Publish date is newer than...',
      name: 'settingsNewEpisodesMarkAgeDes',
      desc: '',
      args: [],
    );
  }

  /// `Criteria for marking episodes as new after sync.`
  String get settingsNewEpisodesMarkDes {
    return Intl.message(
      'Criteria for marking episodes as new after sync.',
      name: 'settingsNewEpisodesMarkDes',
      desc: '',
      args: [],
    );
  }

  /// `Duplicate`
  String get settingsNewEpisodesMarkDuplicate {
    return Intl.message(
      'Duplicate',
      name: 'settingsNewEpisodesMarkDuplicate',
      desc: '',
      args: [],
    );
  }

  /// `Duplicate episode versions can be marked as new.`
  String get settingsNewEpisodesMarkDuplicateDes {
    return Intl.message(
      'Duplicate episode versions can be marked as new.',
      name: 'settingsNewEpisodesMarkDuplicateDes',
      desc: '',
      args: [],
    );
  }

  /// `New Podcast`
  String get settingsNewEpisodesMarkNewPodcast {
    return Intl.message(
      'New Podcast',
      name: 'settingsNewEpisodesMarkNewPodcast',
      desc: '',
      args: [],
    );
  }

  /// `Episodes can be marked as new on initial podcast subscription.`
  String get settingsNewEpisodesMarkNewPodcastDes {
    return Intl.message(
      'Episodes can be marked as new on initial podcast subscription.',
      name: 'settingsNewEpisodesMarkNewPodcastDes',
      desc: '',
      args: [],
    );
  }

  /// `Unseen`
  String get settingsNewEpisodesMarkUnseen {
    return Intl.message(
      'Unseen',
      name: 'settingsNewEpisodesMarkUnseen',
      desc: '',
      args: [],
    );
  }

  /// `Episode was not in the database before sync.`
  String get settingsNewEpisodesMarkUnseenDes {
    return Intl.message(
      'Episode was not in the database before sync.',
      name: 'settingsNewEpisodesMarkUnseenDes',
      desc: '',
      args: [],
    );
  }

  /// `Unmark new episodes`
  String get settingsNewEpisodesUnmark {
    return Intl.message(
      'Unmark new episodes',
      name: 'settingsNewEpisodesUnmark',
      desc: '',
      args: [],
    );
  }

  /// `Minimum Age`
  String get settingsNewEpisodesUnmarkAge {
    return Intl.message(
      'Minimum Age',
      name: 'settingsNewEpisodesUnmarkAge',
      desc: '',
      args: [],
    );
  }

  /// `Publish date is older than...`
  String get settingsNewEpisodesUnmarkAgeDes {
    return Intl.message(
      'Publish date is older than...',
      name: 'settingsNewEpisodesUnmarkAgeDes',
      desc: '',
      args: [],
    );
  }

  /// `Criteria for automatically removing the new mark from episodes.`
  String get settingsNewEpisodesUnmarkDes {
    return Intl.message(
      'Criteria for automatically removing the new mark from episodes.',
      name: 'settingsNewEpisodesUnmarkDes',
      desc: '',
      args: [],
    );
  }

  /// `Interacted`
  String get settingsNewEpisodesUnmarkInteracted {
    return Intl.message(
      'Interacted',
      name: 'settingsNewEpisodesUnmarkInteracted',
      desc: '',
      args: [],
    );
  }

  /// `Episode details were opened or episode was selected.`
  String get settingsNewEpisodesUnmarkInteractedDes {
    return Intl.message(
      'Episode details were opened or episode was selected.',
      name: 'settingsNewEpisodesUnmarkInteractedDes',
      desc: '',
      args: [],
    );
  }

  /// `Played`
  String get settingsNewEpisodesUnmarkPlayed {
    return Intl.message(
      'Played',
      name: 'settingsNewEpisodesUnmarkPlayed',
      desc: '',
      args: [],
    );
  }

  /// `Episode was played.`
  String get settingsNewEpisodesUnmarkPlayedDes {
    return Intl.message(
      'Episode was played.',
      name: 'settingsNewEpisodesUnmarkPlayedDes',
      desc: '',
      args: [],
    );
  }

  /// `Wait until next sync`
  String get settingsNewEpisodesUnmarkWaitSync {
    return Intl.message(
      'Wait until next sync',
      name: 'settingsNewEpisodesUnmarkWaitSync',
      desc: '',
      args: [],
    );
  }

  /// `Only remove new marks during sync.`
  String get settingsNewEpisodesUnmarkWaitSyncDes {
    return Intl.message(
      'Only remove new marks during sync.',
      name: 'settingsNewEpisodesUnmarkWaitSyncDes',
      desc: '',
      args: [],
    );
  }

  /// `Pause and resume downloads based on connectivity`
  String get settingsPauseDownloadOnForbiddenConnected {
    return Intl.message(
      'Pause and resume downloads based on connectivity',
      name: 'settingsPauseDownloadOnForbiddenConnected',
      desc: '',
      args: [],
    );
  }

  /// `All downloads will be paused if the connection changes to a forbidden one. All paused downloads will be resumed when the forbidden connection ends.`
  String get settingsPauseDownloadOnForbiddenConnectedDes {
    return Intl.message(
      'All downloads will be paused if the connection changes to a forbidden one. All paused downloads will be resumed when the forbidden connection ends.',
      name: 'settingsPauseDownloadOnForbiddenConnectedDes',
      desc: '',
      args: [],
    );
  }

  /// `Playback`
  String get settingsPlayback {
    return Intl.message(
      'Playback',
      name: 'settingsPlayback',
      desc: '',
      args: [],
    );
  }

  /// `Playback behavior`
  String get settingsPlaybackDes {
    return Intl.message(
      'Playback behavior',
      name: 'settingsPlaybackDes',
      desc: '',
      args: [],
    );
  }

  /// `Audio Player State`
  String get settingsPlayerState {
    return Intl.message(
      'Audio Player State',
      name: 'settingsPlayerState',
      desc: '',
      args: [],
    );
  }

  /// `Episodes popup menu`
  String get settingsPopupMenu {
    return Intl.message(
      'Episodes popup menu',
      name: 'settingsPopupMenu',
      desc: '',
      args: [],
    );
  }

  /// `Change the popup menu of episodes`
  String get settingsPopupMenuDes {
    return Intl.message(
      'Change the popup menu of episodes',
      name: 'settingsPopupMenuDes',
      desc: '',
      args: [],
    );
  }

  /// `Preference`
  String get settingsPrefrence {
    return Intl.message(
      'Preference',
      name: 'settingsPrefrence',
      desc: '',
      args: [],
    );
  }

  /// `Requirements`
  String get settingsRequirements {
    return Intl.message(
      'Requirements',
      name: 'settingsRequirements',
      desc: '',
      args: [],
    );
  }

  /// `All`
  String get settingsRequirementsAll {
    return Intl.message(
      'All',
      name: 'settingsRequirementsAll',
      desc: '',
      args: [],
    );
  }

  /// `Any`
  String get settingsRequirementsAny {
    return Intl.message(
      'Any',
      name: 'settingsRequirementsAny',
      desc: '',
      args: [],
    );
  }

  /// `In addition to the above, require all or any of the below.`
  String get settingsRequirementsDes {
    return Intl.message(
      'In addition to the above, require all or any of the below.',
      name: 'settingsRequirementsDes',
      desc: 'Displayed alongside buttons to pick \'All\' or \'Any\'.',
      args: [],
    );
  }

  /// `Reset`
  String get settingsReset {
    return Intl.message(
      'Reset',
      name: 'settingsReset',
      desc: '',
      args: [],
    );
  }

  /// `Rewind seconds`
  String get settingsRewindSec {
    return Intl.message(
      'Rewind seconds',
      name: 'settingsRewindSec',
      desc: '',
      args: [],
    );
  }

  /// `Change the rewind seconds in player`
  String get settingsRewindSecDes {
    return Intl.message(
      'Change the rewind seconds in player',
      name: 'settingsRewindSecDes',
      desc: '',
      args: [],
    );
  }

  /// `Default search api`
  String get settingsSearchApi {
    return Intl.message(
      'Default search api',
      name: 'settingsSearchApi',
      desc: '',
      args: [],
    );
  }

  /// `Default web search engine`
  String get settingsSearchEngine {
    return Intl.message(
      'Default web search engine',
      name: 'settingsSearchEngine',
      desc: '',
      args: [],
    );
  }

  /// `Search web by default`
  String get settingsSearchMode {
    return Intl.message(
      'Search web by default',
      name: 'settingsSearchMode',
      desc: '',
      args: [],
    );
  }

  /// `Speeds`
  String get settingsSpeeds {
    return Intl.message(
      'Speeds',
      name: 'settingsSpeeds',
      desc: 'Playback speeds setting.',
      args: [],
    );
  }

  /// `Customize the speeds available`
  String get settingsSpeedsDes {
    return Intl.message(
      'Customize the speeds available',
      name: 'settingsSpeedsDes',
      desc: 'Playback speed setting description',
      args: [],
    );
  }

  /// `Auto turn on sleep timer`
  String get settingsSTAuto {
    return Intl.message(
      'Auto turn on sleep timer',
      name: 'settingsSTAuto',
      desc: '',
      args: [],
    );
  }

  /// `Auto start sleep timer at scheduled time.`
  String get settingsSTAutoDes {
    return Intl.message(
      'Auto start sleep timer at scheduled time.',
      name: 'settingsSTAutoDes',
      desc: '',
      args: [],
    );
  }

  /// `Default time`
  String get settingsSTDefaultTime {
    return Intl.message(
      'Default time',
      name: 'settingsSTDefaultTime',
      desc: '',
      args: [],
    );
  }

  /// `Default waiting time for sleep timer.`
  String get settingsSTDefautTimeDes {
    return Intl.message(
      'Default waiting time for sleep timer.',
      name: 'settingsSTDefautTimeDes',
      desc: '',
      args: [],
    );
  }

  /// `Auto sleep timer mode`
  String get settingsSTMode {
    return Intl.message(
      'Auto sleep timer mode',
      name: 'settingsSTMode',
      desc: '',
      args: [],
    );
  }

  /// `Play until end`
  String get settingsSTWaitEpisodeEnd {
    return Intl.message(
      'Play until end',
      name: 'settingsSTWaitEpisodeEnd',
      desc: '',
      args: [],
    );
  }

  /// `Wait until the end of the playing episode to stop playback when sleep timer expires.`
  String get settingsSTWaitEpisodeEndDes {
    return Intl.message(
      'Wait until the end of the playing episode to stop playback when sleep timer expires.',
      name: 'settingsSTWaitEpisodeEndDes',
      desc: '',
      args: [],
    );
  }

  /// `Storage`
  String get settingStorage {
    return Intl.message(
      'Storage',
      name: 'settingStorage',
      desc: '',
      args: [],
    );
  }

  /// `Syncing`
  String get settingsSyncing {
    return Intl.message(
      'Syncing',
      name: 'settingsSyncing',
      desc: '',
      args: [],
    );
  }

  /// `Refresh podcasts in the background`
  String get settingsSyncingDes {
    return Intl.message(
      'Refresh podcasts in the background',
      name: 'settingsSyncingDes',
      desc: '',
      args: [],
    );
  }

  /// `Syncing interval`
  String get settingsSyncingInterval {
    return Intl.message(
      'Syncing interval',
      name: 'settingsSyncingInterval',
      desc: '',
      args: [],
    );
  }

  /// `Tap to open popup menu`
  String get settingsTapToOpenPopupMenu {
    return Intl.message(
      'Tap to open popup menu',
      name: 'settingsTapToOpenPopupMenu',
      desc: '',
      args: [],
    );
  }

  /// `You need to long press to open episode page`
  String get settingsTapToOpenPopupMenuDes {
    return Intl.message(
      'You need to long press to open episode page',
      name: 'settingsTapToOpenPopupMenuDes',
      desc: '',
      args: [],
    );
  }

  /// `Theme`
  String get settingsTheme {
    return Intl.message(
      'Theme',
      name: 'settingsTheme',
      desc: '',
      args: [],
    );
  }

  /// `True Black`
  String get settingsTrueBlack {
    return Intl.message(
      'True Black',
      name: 'settingsTrueBlack',
      desc: '',
      args: [],
    );
  }

  /// `Black surfaces on dark theme`
  String get settingsTrueBlackDes {
    return Intl.message(
      'Black surfaces on dark theme',
      name: 'settingsTrueBlackDes',
      desc: '',
      args: [],
    );
  }

  /// `Use system accent color`
  String get settingsUseSystemAccentColor {
    return Intl.message(
      'Use system accent color',
      name: 'settingsUseSystemAccentColor',
      desc: '',
      args: [],
    );
  }

  /// `Share`
  String get share {
    return Intl.message(
      'Share',
      name: 'share',
      desc: '',
      args: [],
    );
  }

  /// `Show notes font`
  String get showNotesFonts {
    return Intl.message(
      'Show notes font',
      name: 'showNotesFonts',
      desc: '',
      args: [],
    );
  }

  /// `Size`
  String get size {
    return Intl.message(
      'Size',
      name: 'size',
      desc: '',
      args: [],
    );
  }

  /// `Skip seconds at end`
  String get skipSecondsAtEnd {
    return Intl.message(
      'Skip seconds at end',
      name: 'skipSecondsAtEnd',
      desc: '',
      args: [],
    );
  }

  /// `Skip seconds at start`
  String get skipSecondsAtStart {
    return Intl.message(
      'Skip seconds at start',
      name: 'skipSecondsAtStart',
      desc: '',
      args: [],
    );
  }

  /// `Skip silence`
  String get skipSilence {
    return Intl.message(
      'Skip silence',
      name: 'skipSilence',
      desc: 'Feature skip silence',
      args: [],
    );
  }

  /// `Skip to next`
  String get skipToNext {
    return Intl.message(
      'Skip to next',
      name: 'skipToNext',
      desc: '',
      args: [],
    );
  }

  /// `Skip to Previous`
  String get skipToPrevious {
    return Intl.message(
      'Skip to Previous',
      name: 'skipToPrevious',
      desc: '',
      args: [],
    );
  }

  /// `Sleep timer`
  String get sleepTimer {
    return Intl.message(
      'Sleep timer',
      name: 'sleepTimer',
      desc: '',
      args: [],
    );
  }

  /// `Cancel timer`
  String get sleepTimerCancel {
    return Intl.message(
      'Cancel timer',
      name: 'sleepTimerCancel',
      desc: '',
      args: [],
    );
  }

  /// `Start timer`
  String get sleepTimerStart {
    return Intl.message(
      'Start timer',
      name: 'sleepTimerStart',
      desc: 'The timer length is displayed underneath.',
      args: [],
    );
  }

  /// `Waiting for episode to end`
  String get sleepTimerWait {
    return Intl.message(
      'Waiting for episode to end',
      name: 'sleepTimerWait',
      desc: '',
      args: [],
    );
  }

  /// `Sort By`
  String get sortBy {
    return Intl.message(
      'Sort By',
      name: 'sortBy',
      desc: '',
      args: [],
    );
  }

  /// `Sort Order`
  String get sortOrder {
    return Intl.message(
      'Sort Order',
      name: 'sortOrder',
      desc: '',
      args: [],
    );
  }

  /// `Expire At`
  String get sleepTimerExpireAt {
    return Intl.message(
      'Expire At',
      name: 'sleepTimerExpireAt',
      desc: 'The time (as in time of day) at which the sleep timer will end.',
      args: [],
    );
  }

  /// `Wait For (Minutes)`
  String get sleepTimerWaitFor {
    return Intl.message(
      'Wait For (Minutes)',
      name: 'sleepTimerWaitFor',
      desc: 'The time period the sleep timer will run for.',
      args: [],
    );
  }

  /// `Status`
  String get status {
    return Intl.message(
      'Status',
      name: 'status',
      desc: 'gpodder.net status',
      args: [],
    );
  }

  /// `Authentication error`
  String get statusAuthError {
    return Intl.message(
      'Authentication error',
      name: 'statusAuthError',
      desc: 'Sync error',
      args: [],
    );
  }

  /// `Failed`
  String get statusFail {
    return Intl.message(
      'Failed',
      name: 'statusFail',
      desc: 'Sync fail',
      args: [],
    );
  }

  /// `Successful`
  String get statusSuccess {
    return Intl.message(
      'Successful',
      name: 'statusSuccess',
      desc: 'Sync status',
      args: [],
    );
  }

  /// `Stop`
  String get stop {
    return Intl.message(
      'Stop',
      name: 'stop',
      desc: '',
      args: [],
    );
  }

  /// `Subscribe`
  String get subscribe {
    return Intl.message(
      'Subscribe',
      name: 'subscribe',
      desc: '',
      args: [],
    );
  }

  /// `Subscribed`
  String get subscribed {
    return Intl.message(
      'Subscribed',
      name: 'subscribed',
      desc: '',
      args: [],
    );
  }

  /// `Export OPML file of all podcasts`
  String get subscribeExportDes {
    return Intl.message(
      'Export OPML file of all podcasts',
      name: 'subscribeExportDes',
      desc: '',
      args: [],
    );
  }

  /// `Suggest a new name for Tsacdop-Fork!`
  String get suggestName {
    return Intl.message(
      'Suggest a new name for Tsacdop-Fork!',
      name: 'suggestName',
      desc: '',
      args: [],
    );
  }

  /// `Sync`
  String get sync {
    return Intl.message(
      'Sync',
      name: 'sync',
      desc: '',
      args: [],
    );
  }

  /// `Sync finished`
  String get syncFinished {
    return Intl.message(
      'Sync finished',
      name: 'syncFinished',
      desc: '',
      args: [],
    );
  }

  /// `Sync now`
  String get syncNow {
    return Intl.message(
      'Sync now',
      name: 'syncNow',
      desc: '',
      args: [],
    );
  }

  /// `Sync started`
  String get syncStarted {
    return Intl.message(
      'Sync started',
      name: 'syncStarted',
      desc: '',
      args: [],
    );
  }

  /// `System default`
  String get systemDefault {
    return Intl.message(
      'System default',
      name: 'systemDefault',
      desc: '',
      args: [],
    );
  }

  /// `Last time {time}`
  String timeLastPlayed(Object time) {
    return Intl.message(
      'Last time $time',
      name: 'timeLastPlayed',
      desc:
          'Show last time stop position  in player when a episode have been played.',
      args: [time],
    );
  }

  /// `{time} Left`
  String timeLeft(Object time) {
    return Intl.message(
      '$time Left',
      name: 'timeLeft',
      desc: '',
      args: [time],
    );
  }

  /// `To {time}`
  String to(Object time) {
    return Intl.message(
      'To $time',
      name: 'to',
      desc: '',
      args: [time],
    );
  }

  /// `Added to playlist`
  String get toastAddPlaylist {
    return Intl.message(
      'Added to playlist',
      name: 'toastAddPlaylist',
      desc: '',
      args: [],
    );
  }

  /// `Backup restoration failed!`
  String get toastBackupRestoreFailure {
    return Intl.message(
      'Backup restoration failed!',
      name: 'toastBackupRestoreFailure',
      desc: '',
      args: [],
    );
  }

  /// `Backup restoration successful!`
  String get toastBackupRestoreSuccess {
    return Intl.message(
      'Backup restoration successful!',
      name: 'toastBackupRestoreSuccess',
      desc: '',
      args: [],
    );
  }

  /// `Discovery feature reenabled, please reopen the app`
  String get toastDiscovery {
    return Intl.message(
      'Discovery feature reenabled, please reopen the app',
      name: 'toastDiscovery',
      desc:
          'Toast displayed when user tap Discovery Features Again in settings page.',
      args: [],
    );
  }

  /// `File error, subscribing failed`
  String get toastFileError {
    return Intl.message(
      'File error, subscribing failed',
      name: 'toastFileError',
      desc: '',
      args: [],
    );
  }

  /// `File not valid`
  String get toastFileNotValid {
    return Intl.message(
      'File not valid',
      name: 'toastFileNotValid',
      desc: '',
      args: [],
    );
  }

  /// `Home group is not supported`
  String get toastHomeGroupNotSupport {
    return Intl.message(
      'Home group is not supported',
      name: 'toastHomeGroupNotSupport',
      desc: '',
      args: [],
    );
  }

  /// `Settings imported successfully`
  String get toastImportSettingsSuccess {
    return Intl.message(
      'Settings imported successfully',
      name: 'toastImportSettingsSuccess',
      desc: '',
      args: [],
    );
  }

  /// `Select at least one group`
  String get toastOneGroup {
    return Intl.message(
      'Select at least one group',
      name: 'toastOneGroup',
      desc: '',
      args: [],
    );
  }

  /// `Recovering, wait for a moment`
  String get toastPodcastRecovering {
    return Intl.message(
      'Recovering, wait for a moment',
      name: 'toastPodcastRecovering',
      desc: 'Resubscribe removed podcast',
      args: [],
    );
  }

  /// `File read successfully`
  String get toastReadFile {
    return Intl.message(
      'File read successfully',
      name: 'toastReadFile',
      desc: '',
      args: [],
    );
  }

  /// `Podcast recover failed`
  String get toastRecoverFailed {
    return Intl.message(
      'Podcast recover failed',
      name: 'toastRecoverFailed',
      desc: 'Resubscribe removed podast',
      args: [],
    );
  }

  /// `Episode removed from playlist`
  String get toastRemovePlaylist {
    return Intl.message(
      'Episode removed from playlist',
      name: 'toastRemovePlaylist',
      desc: '',
      args: [],
    );
  }

  /// `Reset successful!`
  String get toastResetSuccessful {
    return Intl.message(
      'Reset successful!',
      name: 'toastResetSuccessful',
      desc: '',
      args: [],
    );
  }

  /// `Please restart the app immediately.`
  String get toastRestart {
    return Intl.message(
      'Please restart the app immediately.',
      name: 'toastRestart',
      desc: '',
      args: [],
    );
  }

  /// `Settings saved`
  String get toastSettingSaved {
    return Intl.message(
      'Settings saved',
      name: 'toastSettingSaved',
      desc: '',
      args: [],
    );
  }

  /// `Time is equal to end time`
  String get toastTimeEqualEnd {
    return Intl.message(
      'Time is equal to end time',
      name: 'toastTimeEqualEnd',
      desc: 'User can\'t choose the same time as schedule end time.',
      args: [],
    );
  }

  /// `Time is equal to start time`
  String get toastTimeEqualStart {
    return Intl.message(
      'Time is equal to start time',
      name: 'toastTimeEqualStart',
      desc: 'User can\'t choose the same time as schedule start time.',
      args: [],
    );
  }

  /// `Translators`
  String get translators {
    return Intl.message(
      'Translators',
      name: 'translators',
      desc: '',
      args: [],
    );
  }

  /// `Translate`
  String get translate {
    return Intl.message(
      'Translate',
      name: 'translate',
      desc: '',
      args: [],
    );
  }

  /// `Understood`
  String get understood {
    return Intl.message(
      'Understood',
      name: 'understood',
      desc: '',
      args: [],
    );
  }

  /// `UNDO`
  String get undo {
    return Intl.message(
      'UNDO',
      name: 'undo',
      desc: '',
      args: [],
    );
  }

  /// `Unlike`
  String get unlike {
    return Intl.message(
      'Unlike',
      name: 'unlike',
      desc: '',
      args: [],
    );
  }

  /// `Episode removed from favorites`
  String get unliked {
    return Intl.message(
      'Episode removed from favorites',
      name: 'unliked',
      desc: '',
      args: [],
    );
  }

  /// `Unsupported`
  String get unsupported {
    return Intl.message(
      'Unsupported',
      name: 'unsupported',
      desc: '',
      args: [],
    );
  }

  /// `Update date`
  String get updateDate {
    return Intl.message(
      'Update date',
      name: 'updateDate',
      desc: '',
      args: [],
    );
  }

  /// `{count, plural, zero{No update} one{Updated {count} episode} other{Updated {count} episodes}}`
  String updateEpisodesCount(num count) {
    return Intl.plural(
      count,
      zero: 'No update',
      one: 'Updated $count episode',
      other: 'Updated $count episodes',
      name: 'updateEpisodesCount',
      desc: '',
      args: [count],
    );
  }

  /// `Update failed, network error`
  String get updateFailed {
    return Intl.message(
      'Update failed, network error',
      name: 'updateFailed',
      desc: '',
      args: [],
    );
  }

  /// `Username`
  String get username {
    return Intl.message(
      'Username',
      name: 'username',
      desc: '',
      args: [],
    );
  }

  /// `Username required`
  String get usernameRequired {
    return Intl.message(
      'Username required',
      name: 'usernameRequired',
      desc: '',
      args: [],
    );
  }

  /// `Version: {version}`
  String version(Object version) {
    return Intl.message(
      'Version: $version',
      name: 'version',
      desc: '',
      args: [version],
    );
  }

  /// `VPN`
  String get vpn {
    return Intl.message(
      'VPN',
      name: 'vpn',
      desc: '',
      args: [],
    );
  }

  /// `Welcome to Tsacdop!`
  String get welcome {
    return Intl.message(
      'Welcome to Tsacdop!',
      name: 'welcome',
      desc: '',
      args: [],
    );
  }

  /// `{count, plural, zero{{count} weeks} one{{count} week} other{{count} weeks}}`
  String weeksCount(num count) {
    return Intl.plural(
      count,
      zero: '$count weeks',
      one: '$count week',
      other: '$count weeks',
      name: 'weeksCount',
      desc: '',
      args: [count],
    );
  }

  /// `Wi-Fi`
  String get wifi {
    return Intl.message(
      'Wi-Fi',
      name: 'wifi',
      desc: '',
      args: [],
    );
  }

  /// `{count, plural, zero{{count} years} one{{count} year} other{{count} years}}`
  String yearsCount(num count) {
    return Intl.plural(
      count,
      zero: '$count years',
      one: '$count year',
      other: '$count years',
      name: 'yearsCount',
      desc: '',
      args: [count],
    );
  }
}

class AppLocalizationDelegate extends LocalizationsDelegate<S> {
  const AppLocalizationDelegate();

  List<Locale> get supportedLocales {
    return const <Locale>[
      Locale.fromSubtags(languageCode: 'en'),
      Locale.fromSubtags(languageCode: 'cs'),
      Locale.fromSubtags(languageCode: 'de'),
      Locale.fromSubtags(languageCode: 'el'),
      Locale.fromSubtags(languageCode: 'es'),
      Locale.fromSubtags(languageCode: 'fr'),
      Locale.fromSubtags(languageCode: 'it'),
      Locale.fromSubtags(languageCode: 'pt'),
      Locale.fromSubtags(languageCode: 'ru'),
      Locale.fromSubtags(languageCode: 'tr'),
      Locale.fromSubtags(languageCode: 'zh', scriptCode: 'Hans'),
    ];
  }

  @override
  bool isSupported(Locale locale) => _isSupported(locale);
  @override
  Future<S> load(Locale locale) => S.load(locale);
  @override
  bool shouldReload(AppLocalizationDelegate old) => false;

  bool _isSupported(Locale locale) {
    for (var supportedLocale in supportedLocales) {
      if (supportedLocale.languageCode == locale.languageCode) {
        return true;
      }
    }
    return false;
  }
}
