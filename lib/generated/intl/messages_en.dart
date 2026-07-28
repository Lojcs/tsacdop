// DO NOT EDIT. This is code generated via package:intl/generate_localized.dart
// This is a library that provides messages for a en locale. All the
// messages from the main program should be duplicated here with the same
// function name.

// Ignore issues from commonly used lints in this file.
// ignore_for_file:unnecessary_brace_in_string_interps, unnecessary_new
// ignore_for_file:prefer_single_quotes,comment_references, directives_ordering
// ignore_for_file:annotate_overrides,prefer_generic_function_type_aliases
// ignore_for_file:unused_import, file_names, avoid_escaping_inner_quotes
// ignore_for_file:unnecessary_string_interpolations, unnecessary_string_escapes

import 'package:intl/intl.dart';
import 'package:intl/message_lookup_by_library.dart';

final messages = new MessageLookup();

typedef String MessageIfAbsent(String messageStr, List<dynamic> args);

class MessageLookup extends MessageLookupByLibrary {
  String get localeName => 'en';

  static String m2(groupName, count) =>
      "${Intl.plural(count, zero: '', one: '${count} episode in ${groupName} added to playlist', other: '${count} episodes in ${groupName} added to playlist')}";

  static String m3(count) =>
      "${Intl.plural(count, zero: '', one: '${count} episode added to playlist', other: '${count} episodes added to playlist')}";

  static String m4(count) =>
      "${Intl.plural(count, zero: 'Today', one: '${count} day ago', other: '${count} days ago')}";

  static String m5(count) =>
      "${Intl.plural(count, zero: '${count} days', one: '${count} day', other: '${count} days')}";

  static String m6(count) =>
      "${Intl.plural(count, zero: '', one: 'Episode', other: 'Episodes')}";

  static String m32(type) => "${type} Filter";

  static String m7(time) => "From ${time}";

  static String m33(icon) => "Tap ${icon} to search podcasts";

  static String m8(count) =>
      "${Intl.plural(count, zero: 'Group', one: 'Group', other: 'Groups')}";

  static String m0(host) => "Hosted on ${host}";

  static String m9(count) =>
      "${Intl.plural(count, zero: 'This hour', one: '${count} hour ago', other: '${count} hours ago')}";

  static String m10(count) =>
      "${Intl.plural(count, zero: '0 hours', one: '${count} hour', other: '${count} hours')}";

  static String m11(service) => "Integrate with ${service}";

  static String m34(filePath) => "Local episode at ${filePath}";

  static String m1(userName) => "Logged in as ${userName}";

  static String m12(count) =>
      "${Intl.plural(count, zero: 'Just now', one: '${count} minute ago', other: '${count} minutes ago')}";

  static String m13(count) =>
      "${Intl.plural(count, zero: '0 min', one: '${count} min', other: '${count} mins')}";

  static String m35(count) =>
      "${Intl.plural(count, zero: '${count} months', one: '${count} month', other: '${count} months')}";

  static String m14(title) => "Fetch data ${title}";

  static String m15(title) => "Subscribing failed, network error ${title}";

  static String m16(title) => "Subscribe ${title}";

  static String m17(title) =>
      "Subscribing failed, podcast already exists ${title}";

  static String m18(title) => "Subscribed successfully ${title}";

  static String m19(title) => "Update ${title}";

  static String m20(title) => "Update error ${title}";

  static String m21(count) =>
      "${Intl.plural(count, zero: '', one: 'Podcast', other: 'Podcasts')}";

  static String m22(date) => "Published at ${date}";

  static String m23(date) => "Removed at ${date}";

  static String m36(start, end) => "Schedule: ${start} - ${end}";

  static String m24(count) =>
      "${Intl.plural(count, zero: '0 sec', one: '${count} sec', other: '${count} sec')}";

  static String m25(count) =>
      "${Intl.plural(count, zero: 'Just now', one: '${count} second ago', other: '${count} seconds ago')}";

  static String m26(count) => "${count} selected";

  static String m27(time) => "Last time ${time}";

  static String m28(time) => "${time} Left";

  static String m29(time) => "To ${time}";

  static String m30(count) =>
      "${Intl.plural(count, zero: 'No update', one: 'Updated ${count} episode', other: 'Updated ${count} episodes')}";

  static String m31(version) => "Version: ${version}";

  static String m37(count) =>
      "${Intl.plural(count, zero: '${count} weeks', one: '${count} week', other: '${count} weeks')}";

  static String m38(count) =>
      "${Intl.plural(count, zero: '${count} years', one: '${count} year', other: '${count} years')}";

  final messages = _notInlinedMessages(_notInlinedMessages);
  static Map<String, Function> _notInlinedMessages(_) => <String, Function>{
        "add": MessageLookupByLibrary.simpleMessage("Add"),
        "addEpisodeGroup": m2,
        "addNewEpisodeAll": m3,
        "addNewEpisodeTooltip": MessageLookupByLibrary.simpleMessage(
            "Add new episodes to playlist"),
        "addSomeGroups":
            MessageLookupByLibrary.simpleMessage("Add some groups"),
        "after": MessageLookupByLibrary.simpleMessage("After"),
        "all": MessageLookupByLibrary.simpleMessage("All"),
        "apiSearch": MessageLookupByLibrary.simpleMessage("Api Search"),
        "autoDownload": MessageLookupByLibrary.simpleMessage("Auto download"),
        "back": MessageLookupByLibrary.simpleMessage("Back"),
        "before": MessageLookupByLibrary.simpleMessage("Before"),
        "between": MessageLookupByLibrary.simpleMessage("Between"),
        "boostVolume": MessageLookupByLibrary.simpleMessage("Boost volume"),
        "buffering": MessageLookupByLibrary.simpleMessage("Buffering"),
        "cancel": MessageLookupByLibrary.simpleMessage("CANCEL"),
        "capitalDefault": MessageLookupByLibrary.simpleMessage("Default"),
        "cellularConfirm":
            MessageLookupByLibrary.simpleMessage("Cellular data warning"),
        "cellularConfirmDes": MessageLookupByLibrary.simpleMessage(
            "Are you sure you want to use cellular data to download?"),
        "changeLayout": MessageLookupByLibrary.simpleMessage("Change layout"),
        "changelog": MessageLookupByLibrary.simpleMessage("Changelog"),
        "chooseA": MessageLookupByLibrary.simpleMessage("Choose a"),
        "clear": MessageLookupByLibrary.simpleMessage("Clear"),
        "clearAll": MessageLookupByLibrary.simpleMessage("Clear all"),
        "close": MessageLookupByLibrary.simpleMessage("Close"),
        "color": MessageLookupByLibrary.simpleMessage("color"),
        "confirm": MessageLookupByLibrary.simpleMessage("CONFIRM"),
        "confirmation": MessageLookupByLibrary.simpleMessage("Confirmation"),
        "createNewPlaylist":
            MessageLookupByLibrary.simpleMessage("New playlist"),
        "darkMode": MessageLookupByLibrary.simpleMessage("Dark mode"),
        "daysAgo": m4,
        "daysCount": m5,
        "defaultQueueReminder": MessageLookupByLibrary.simpleMessage(
            "This is the default queue, can\'\'t be removed."),
        "defaultSearchEngine": MessageLookupByLibrary.simpleMessage(
            "Default podcast search engine"),
        "defaultSearchEngineDes": MessageLookupByLibrary.simpleMessage(
            "Choose the default podcast search engine"),
        "delete": MessageLookupByLibrary.simpleMessage("Delete"),
        "deleted": MessageLookupByLibrary.simpleMessage("Deleted"),
        "deletedEpisodeDesc": MessageLookupByLibrary.simpleMessage(
            "This episode has been deleted from the database"),
        "deletedPodcastDesc": MessageLookupByLibrary.simpleMessage(
            "This podcast has been deleted from the database"),
        "deselectAll": MessageLookupByLibrary.simpleMessage("Deselect All"),
        "details": MessageLookupByLibrary.simpleMessage("Details"),
        "developer": MessageLookupByLibrary.simpleMessage("Developer"),
        "deviceStorage": MessageLookupByLibrary.simpleMessage("Device Storage"),
        "disabled": MessageLookupByLibrary.simpleMessage("Disabled"),
        "dismiss": MessageLookupByLibrary.simpleMessage("Dismiss"),
        "displayVersion":
            MessageLookupByLibrary.simpleMessage("Display Version"),
        "done": MessageLookupByLibrary.simpleMessage("Done"),
        "download": MessageLookupByLibrary.simpleMessage("Download"),
        "downloadDate": MessageLookupByLibrary.simpleMessage("Download Date"),
        "downloadRemovedToast":
            MessageLookupByLibrary.simpleMessage("Download removed"),
        "downloadStart": MessageLookupByLibrary.simpleMessage("Downloading"),
        "downloaded": MessageLookupByLibrary.simpleMessage("Downloaded"),
        "downloading": MessageLookupByLibrary.simpleMessage("Downloading"),
        "duration": MessageLookupByLibrary.simpleMessage("Duration"),
        "editGroupName":
            MessageLookupByLibrary.simpleMessage("Edit group name"),
        "endOfEpisode": MessageLookupByLibrary.simpleMessage("Play until end"),
        "episode": m6,
        "fastForward": MessageLookupByLibrary.simpleMessage("Fast forward"),
        "fastRewind": MessageLookupByLibrary.simpleMessage("Fast rewind"),
        "featureDiscoveryEditGroup":
            MessageLookupByLibrary.simpleMessage("Tap to edit group"),
        "featureDiscoveryEditGroupDes": MessageLookupByLibrary.simpleMessage(
            "You can change group name or delete it here, but the home group can not be edited or deleted"),
        "featureDiscoveryEpisode":
            MessageLookupByLibrary.simpleMessage("Episode view"),
        "featureDiscoveryEpisodeDes": MessageLookupByLibrary.simpleMessage(
            "You can long press to play episode or add it to a playlist."),
        "featureDiscoveryEpisodeTitle": MessageLookupByLibrary.simpleMessage(
            "Long press to play episode instantly"),
        "featureDiscoveryGroup":
            MessageLookupByLibrary.simpleMessage("Tap to add group"),
        "featureDiscoveryGroupDes": MessageLookupByLibrary.simpleMessage(
            "The Home group is the default group for new podcasts. You can create new groups and move podcasts to them as well as add podcasts to multiple groups."),
        "featureDiscoveryGroupPodcast": MessageLookupByLibrary.simpleMessage(
            "Long press to reorder podcasts"),
        "featureDiscoveryGroupPodcastDes": MessageLookupByLibrary.simpleMessage(
            "You can tap to see more options, or long press to reorder podcasts in group."),
        "featureDiscoveryOMPL":
            MessageLookupByLibrary.simpleMessage("Tap to import OPML"),
        "featureDiscoveryOMPLDes": MessageLookupByLibrary.simpleMessage(
            "You can import OPML files, open settings or refresh all podcasts at once here."),
        "featureDiscoveryPlaylist":
            MessageLookupByLibrary.simpleMessage("Tap to open playlist"),
        "featureDiscoveryPlaylistDes": MessageLookupByLibrary.simpleMessage(
            "You can add episodes to playlists by yourself. Episodes will be automatically removed from playlists when played."),
        "featureDiscoveryPodcast":
            MessageLookupByLibrary.simpleMessage("Podcast view"),
        "featureDiscoveryPodcastDes": MessageLookupByLibrary.simpleMessage(
            "You can tap See All to add groups or manage podcasts."),
        "featureDiscoveryPodcastTitle": MessageLookupByLibrary.simpleMessage(
            "Scroll vertically to switch groups"),
        "featureDiscoverySearch":
            MessageLookupByLibrary.simpleMessage("Tap to search for podcasts"),
        "featureDiscoverySearchDes": MessageLookupByLibrary.simpleMessage(
            "You can search by podcast title, key word or RSS link to subscribe to new podcasts."),
        "feedbackEmail": MessageLookupByLibrary.simpleMessage("Write to me"),
        "feedbackGithub": MessageLookupByLibrary.simpleMessage("Submit issue"),
        "feedbackPlay":
            MessageLookupByLibrary.simpleMessage("Rate on Play Store"),
        "feedbackTelegram": MessageLookupByLibrary.simpleMessage("Join group"),
        "filter": MessageLookupByLibrary.simpleMessage("Filter"),
        "filterType": m32,
        "fontStyle": MessageLookupByLibrary.simpleMessage("Font style"),
        "fonts": MessageLookupByLibrary.simpleMessage("Fonts"),
        "forward": MessageLookupByLibrary.simpleMessage("Forward"),
        "from": m7,
        "getStarted": MessageLookupByLibrary.simpleMessage("Get started"),
        "getStartedDes": m33,
        "globallyDisabled":
            MessageLookupByLibrary.simpleMessage("Globally disabled"),
        "goodNight": MessageLookupByLibrary.simpleMessage("Good Night"),
        "gpodderLoginDes": MessageLookupByLibrary.simpleMessage(
            "Congratulations! You  have linked gpodder.net account successfully. Tsacdop will automatically sync subscriptions on your device with your gpodder.net account."),
        "groupExisted":
            MessageLookupByLibrary.simpleMessage("Group already exists"),
        "groupRemoveConfirm": MessageLookupByLibrary.simpleMessage(
            "Are you sure you want to delete this group? Podcasts will be moved to the Home group."),
        "groups": m8,
        "haptics": MessageLookupByLibrary.simpleMessage("Haptic Feedback"),
        "hapticsDes": MessageLookupByLibrary.simpleMessage(
            "Toggle haptic feedback and adjust its intensity. (Requires device support)"),
        "hideListenedSetting":
            MessageLookupByLibrary.simpleMessage("Hide listened"),
        "hidePodcastDiscovery":
            MessageLookupByLibrary.simpleMessage("Hide podcast discovery"),
        "hidePodcastDiscoveryDes": MessageLookupByLibrary.simpleMessage(
            "Hide podcast discovery in search page"),
        "homeGroupsSeeAll": MessageLookupByLibrary.simpleMessage("See All"),
        "homeMenuPlaylist": MessageLookupByLibrary.simpleMessage("Playlist"),
        "homeSubMenuSortBy": MessageLookupByLibrary.simpleMessage("Sort by"),
        "homeTabMenuFavotite": MessageLookupByLibrary.simpleMessage("Favorite"),
        "homeTabMenuRecent": MessageLookupByLibrary.simpleMessage("Recent"),
        "homeToprightMenuAbout": MessageLookupByLibrary.simpleMessage("About"),
        "homeToprightMenuImportOMPL":
            MessageLookupByLibrary.simpleMessage("Import OPML"),
        "homeToprightMenuRefreshAll":
            MessageLookupByLibrary.simpleMessage("Refresh all"),
        "hostedOn": m0,
        "hoursAgo": m9,
        "hoursCount": m10,
        "import": MessageLookupByLibrary.simpleMessage("Import"),
        "importingOpml":
            MessageLookupByLibrary.simpleMessage("Importing OPML file."),
        "interaction": MessageLookupByLibrary.simpleMessage("Interaction"),
        "intergateWith": m11,
        "introFourthPage": MessageLookupByLibrary.simpleMessage(
            "You can long press on episode card for quick actions."),
        "introSecondPage": MessageLookupByLibrary.simpleMessage(
            "Subscribe podcast via search or import OPML file."),
        "introThirdPage": MessageLookupByLibrary.simpleMessage(
            "You can create new group for podcasts."),
        "invalidName": MessageLookupByLibrary.simpleMessage("Invalid username"),
        "keepAndroidOpen": MessageLookupByLibrary.simpleMessage(
            "Google wants to control which apps you can install on your phone."),
        "keepAndroidOpenDes": MessageLookupByLibrary.simpleMessage(
            "Learn more and make you voice heard on keepandroidopen.org."),
        "lastUpdate": MessageLookupByLibrary.simpleMessage("Last update"),
        "later": MessageLookupByLibrary.simpleMessage("Later"),
        "lightMode": MessageLookupByLibrary.simpleMessage("Light mode"),
        "like": MessageLookupByLibrary.simpleMessage("Like"),
        "likeDate": MessageLookupByLibrary.simpleMessage("Like date"),
        "liked": MessageLookupByLibrary.simpleMessage("Liked"),
        "listen": MessageLookupByLibrary.simpleMessage("Listen"),
        "listened": MessageLookupByLibrary.simpleMessage("Listened"),
        "loadAllSelected":
            MessageLookupByLibrary.simpleMessage("Load All Selected"),
        "loadMore": MessageLookupByLibrary.simpleMessage("Load more"),
        "loading": MessageLookupByLibrary.simpleMessage("Loading"),
        "localEpisodeDescription": m34,
        "localFolder": MessageLookupByLibrary.simpleMessage("Local Folder"),
        "localFolderDescription": MessageLookupByLibrary.simpleMessage(
            "Dummy podcast that collects imported local audio files."),
        "localizationWeblate": MessageLookupByLibrary.simpleMessage(
            "You can contribute to the localization of this app on hosted Weblate thanks to their support of open source projects."),
        "loggedInAs": m1,
        "login": MessageLookupByLibrary.simpleMessage("Login"),
        "loginFailed": MessageLookupByLibrary.simpleMessage("Login failed"),
        "logout": MessageLookupByLibrary.simpleMessage("Logout"),
        "mark": MessageLookupByLibrary.simpleMessage("Mark"),
        "markConfirm": MessageLookupByLibrary.simpleMessage("Confirm marking"),
        "markConfirmContent": MessageLookupByLibrary.simpleMessage(
            "Confirm to mark all episodes as listened?"),
        "markListened":
            MessageLookupByLibrary.simpleMessage("Mark as listened"),
        "markNotListened":
            MessageLookupByLibrary.simpleMessage("Mark not listened"),
        "menu": MessageLookupByLibrary.simpleMessage("Menu"),
        "menuAllPodcasts": MessageLookupByLibrary.simpleMessage("All podcasts"),
        "menuMarkAllListened":
            MessageLookupByLibrary.simpleMessage("Mark All As Listened"),
        "menuViewRSS": MessageLookupByLibrary.simpleMessage("Visit RSS Feed"),
        "menuVisitSite": MessageLookupByLibrary.simpleMessage("Visit Site"),
        "minsAgo": m12,
        "minsCount": m13,
        "mobileData": MessageLookupByLibrary.simpleMessage("Mobile Data"),
        "monthsCount": m35,
        "moreOptions": MessageLookupByLibrary.simpleMessage("More Options"),
        "network": MessageLookupByLibrary.simpleMessage("Network"),
        "networkErrorDNS":
            MessageLookupByLibrary.simpleMessage("Network error (DNS issue)"),
        "neverAutoUpdate": MessageLookupByLibrary.simpleMessage(
            "Don\'t include in global sync"),
        "neverAutoUpdateDes": MessageLookupByLibrary.simpleMessage(
            "The podcast can still be synced on its own."),
        "newGroup": MessageLookupByLibrary.simpleMessage("Create new group"),
        "newPlain": MessageLookupByLibrary.simpleMessage("New"),
        "newPlaylist": MessageLookupByLibrary.simpleMessage("New Playlist"),
        "newestFirst": MessageLookupByLibrary.simpleMessage("Newest first"),
        "next": MessageLookupByLibrary.simpleMessage("Next"),
        "noEpisodesFound": MessageLookupByLibrary.simpleMessage(
            "No episodes found with given filters"),
        "noPodcastGroup":
            MessageLookupByLibrary.simpleMessage("No podcasts in this group"),
        "noShownote": MessageLookupByLibrary.simpleMessage(
            "No show notes available for this episode."),
        "none": MessageLookupByLibrary.simpleMessage("None"),
        "notificaitonFatch": m14,
        "notificationAddingGroups": MessageLookupByLibrary.simpleMessage(
            "Adding and organizing groups."),
        "notificationNetworkError": m15,
        "notificationSubscribe": m16,
        "notificationSubscribeExisted": m17,
        "notificationSubscribing":
            MessageLookupByLibrary.simpleMessage("Subscribing to podcasts."),
        "notificationSuccess": m18,
        "notificationUpdate": m19,
        "notificationUpdateError": m20,
        "oldestFirst": MessageLookupByLibrary.simpleMessage("Oldest first"),
        "opmlFile": MessageLookupByLibrary.simpleMessage("OPML file"),
        "passwdRequired":
            MessageLookupByLibrary.simpleMessage("Password required"),
        "password": MessageLookupByLibrary.simpleMessage("Password"),
        "pause": MessageLookupByLibrary.simpleMessage("Pause"),
        "play": MessageLookupByLibrary.simpleMessage("Play"),
        "playNext": MessageLookupByLibrary.simpleMessage("Play next"),
        "playNextDes": MessageLookupByLibrary.simpleMessage(
            "Add episode to top of the playlist"),
        "playback": MessageLookupByLibrary.simpleMessage("Playback control"),
        "player": MessageLookupByLibrary.simpleMessage("Player"),
        "playerHeightMed": MessageLookupByLibrary.simpleMessage("Medium"),
        "playerHeightShort": MessageLookupByLibrary.simpleMessage("Low"),
        "playerHeightTall": MessageLookupByLibrary.simpleMessage("High"),
        "playing": MessageLookupByLibrary.simpleMessage("Playing"),
        "playlistExists":
            MessageLookupByLibrary.simpleMessage("Playlist already exists"),
        "playlistNameEmpty":
            MessageLookupByLibrary.simpleMessage("Playlist name is empty"),
        "playlists": MessageLookupByLibrary.simpleMessage("Playlists"),
        "plugins": MessageLookupByLibrary.simpleMessage("Plugins"),
        "podcast": m21,
        "podcastList": MessageLookupByLibrary.simpleMessage("Podcast List"),
        "podcastSubscribed":
            MessageLookupByLibrary.simpleMessage("Podcast subscribed"),
        "popupMenuDownloadDes":
            MessageLookupByLibrary.simpleMessage("Download episode"),
        "popupMenuLaterDes":
            MessageLookupByLibrary.simpleMessage("Add episode to playlist"),
        "popupMenuLikeDes":
            MessageLookupByLibrary.simpleMessage("Add episode to favorite"),
        "popupMenuMarkDes":
            MessageLookupByLibrary.simpleMessage("Mark episode as listened to"),
        "popupMenuPlayDes":
            MessageLookupByLibrary.simpleMessage("Play the episode"),
        "privacyPolicy": MessageLookupByLibrary.simpleMessage("Privacy Policy"),
        "publishDate": MessageLookupByLibrary.simpleMessage("Publish Date"),
        "published": m22,
        "publishedDaily":
            MessageLookupByLibrary.simpleMessage("Published daily"),
        "publishedMonthly":
            MessageLookupByLibrary.simpleMessage("Published monthly"),
        "publishedWeekly":
            MessageLookupByLibrary.simpleMessage("Published weekly"),
        "publishedYearly":
            MessageLookupByLibrary.simpleMessage("Published yearly"),
        "queue": MessageLookupByLibrary.simpleMessage("Queue"),
        "random": MessageLookupByLibrary.simpleMessage("Random"),
        "recoverSubscribe":
            MessageLookupByLibrary.simpleMessage("Recover subscribe"),
        "refresh": MessageLookupByLibrary.simpleMessage("Refresh"),
        "refreshArtwork":
            MessageLookupByLibrary.simpleMessage("Update artwork"),
        "remove": MessageLookupByLibrary.simpleMessage("Remove"),
        "removeConfirm":
            MessageLookupByLibrary.simpleMessage("Removal confirmation"),
        "removeDownload":
            MessageLookupByLibrary.simpleMessage("Remove Download"),
        "removeNewMark":
            MessageLookupByLibrary.simpleMessage("Remove new mark"),
        "removePodcastDes": MessageLookupByLibrary.simpleMessage(
            "Are you sure you want to unsubscribe?"),
        "removedAt": m23,
        "restartAppForEffect": MessageLookupByLibrary.simpleMessage(
            "Restart the app for the changes to take effect."),
        "satellite": MessageLookupByLibrary.simpleMessage("Satellite"),
        "save": MessageLookupByLibrary.simpleMessage("Save"),
        "schedule": MessageLookupByLibrary.simpleMessage("Schedule"),
        "scheduleDisabled":
            MessageLookupByLibrary.simpleMessage("Schedule disabled."),
        "scheduleTime": m36,
        "search": MessageLookupByLibrary.simpleMessage("Search"),
        "searchApi": MessageLookupByLibrary.simpleMessage("Search Api"),
        "searchEngine": MessageLookupByLibrary.simpleMessage("Search Engine"),
        "searchEpisode": MessageLookupByLibrary.simpleMessage("Search episode"),
        "searchHelper": MessageLookupByLibrary.simpleMessage(
            "Type the podcast name, keywords or enter a feed url."),
        "searchInstructions": MessageLookupByLibrary.simpleMessage(
            "Enter an rss feed url or search for a podcast and open its rss feed to subscribe."),
        "searchInvalidRss":
            MessageLookupByLibrary.simpleMessage("Invalid RSS link"),
        "searchPodcast":
            MessageLookupByLibrary.simpleMessage("Search for podcasts"),
        "searchWeb": MessageLookupByLibrary.simpleMessage("Web Search"),
        "secCount": m24,
        "secondsAgo": m25,
        "selectMode": MessageLookupByLibrary.simpleMessage("Selection Mode"),
        "selected": m26,
        "settingStorage": MessageLookupByLibrary.simpleMessage("Storage"),
        "settings": MessageLookupByLibrary.simpleMessage("Settings"),
        "settingsAccentColor":
            MessageLookupByLibrary.simpleMessage("Accent color"),
        "settingsAppIntro": MessageLookupByLibrary.simpleMessage("App Intro"),
        "settingsAppearance":
            MessageLookupByLibrary.simpleMessage("Appearance"),
        "settingsAppearanceDes":
            MessageLookupByLibrary.simpleMessage("Colors and themes"),
        "settingsAudioCache":
            MessageLookupByLibrary.simpleMessage("Audio cache"),
        "settingsAudioCacheDes":
            MessageLookupByLibrary.simpleMessage("Audio cache max size"),
        "settingsAutoDelete":
            MessageLookupByLibrary.simpleMessage("Auto delete"),
        "settingsAutoDeleteAfterPlayed":
            MessageLookupByLibrary.simpleMessage("Delete played downloads"),
        "settingsAutoDeleteAfterTime":
            MessageLookupByLibrary.simpleMessage("Delete old downloads"),
        "settingsAutoDeleteAfterTimeDes": MessageLookupByLibrary.simpleMessage(
            "Delete downloads older than..."),
        "settingsAutoDeleteDes": MessageLookupByLibrary.simpleMessage(
            "Deletions are performed on app start and on sync."),
        "settingsAutoDeleteOldestIfTotalAbove":
            MessageLookupByLibrary.simpleMessage("Limit downloads storage"),
        "settingsAutoDeleteOldestIfTotalAboveDes":
            MessageLookupByLibrary.simpleMessage(
                "If total size of audio downloads exceeds this, the oldest downloads will be deleted."),
        "settingsAutoDownload":
            MessageLookupByLibrary.simpleMessage("Auto download"),
        "settingsAutoDownloadDes": MessageLookupByLibrary.simpleMessage(
            "Download episodes marked new after sync."),
        "settingsAutoDownloadOnForbidden": MessageLookupByLibrary.simpleMessage(
            "Auto download on forbidden connections"),
        "settingsAutoDownloadOnForbiddenDes": MessageLookupByLibrary.simpleMessage(
            "If disabled, auto downloads starting on forbidden connections will be immediately paused."),
        "settingsAutoPlayDes": MessageLookupByLibrary.simpleMessage(
            "Auto play the next episode when an episode ends."),
        "settingsBackup": MessageLookupByLibrary.simpleMessage("Backup"),
        "settingsBackupCategories":
            MessageLookupByLibrary.simpleMessage("Categories"),
        "settingsBackupCategoriesDes": MessageLookupByLibrary.simpleMessage(
            "Settings categories to export, import or reset."),
        "settingsBackupCategoriesImportDes":
            MessageLookupByLibrary.simpleMessage(
                "Settings categories to import."),
        "settingsBackupConfirmationDatabaseOverwrite":
            MessageLookupByLibrary.simpleMessage(
                "Are you sure you want to wipe the selected database categories and replace them with the backup?"),
        "settingsBackupConfirmationDatabaseReset":
            MessageLookupByLibrary.simpleMessage(
                "Are you sure you want to reset the selected database categories?"),
        "settingsBackupConfirmationSettingsOverwrite":
            MessageLookupByLibrary.simpleMessage(
                "Are you sure you want to overwrite the current settings in the selected categories?"),
        "settingsBackupConfirmationSettingsReset":
            MessageLookupByLibrary.simpleMessage(
                "Are you sure you want to reset settings in the selected categories to default?"),
        "settingsBackupDatabase":
            MessageLookupByLibrary.simpleMessage("Database"),
        "settingsBackupDatabaseBackupFile":
            MessageLookupByLibrary.simpleMessage("Database file"),
        "settingsBackupDatabaseBackupFileDes":
            MessageLookupByLibrary.simpleMessage(
                "Export, import and reset app data."),
        "settingsBackupDatabaseCategoriesDes":
            MessageLookupByLibrary.simpleMessage(
                "Database categories to export, import or reset."),
        "settingsBackupDatabaseHistory": MessageLookupByLibrary.simpleMessage(
            "Playback and subscription history"),
        "settingsBackupDatabasePlaylists":
            MessageLookupByLibrary.simpleMessage("Playlists"),
        "settingsBackupDatabasePodcasts": MessageLookupByLibrary.simpleMessage(
            "Podcasts, episodes and groups"),
        "settingsBackupDes":
            MessageLookupByLibrary.simpleMessage("Backup, restore or reset"),
        "settingsBackupFile":
            MessageLookupByLibrary.simpleMessage("Settings Backup File"),
        "settingsBackupLegacyFile":
            MessageLookupByLibrary.simpleMessage("Legacy Settings Backup File"),
        "settingsBackupLegacyFileDes": MessageLookupByLibrary.simpleMessage(
            "Import backups created before v0.10."),
        "settingsBackupPassword":
            MessageLookupByLibrary.simpleMessage("Backup Password"),
        "settingsBackupPasswordDes": MessageLookupByLibrary.simpleMessage(
            "Optional password to encrypt the backup when exporting or decrypt it when importing."),
        "settingsBoostVolume":
            MessageLookupByLibrary.simpleMessage("Volume boost amount"),
        "settingsBoostVolumeDes": MessageLookupByLibrary.simpleMessage(
            "Decibels to boost by when volume boost is enabled."),
        "settingsColors": MessageLookupByLibrary.simpleMessage("Colors"),
        "settingsDefaultFilterAndroidAuto":
            MessageLookupByLibrary.simpleMessage("Android Auto Filters"),
        "settingsDefaultFilterAndroidAutoDes": MessageLookupByLibrary.simpleMessage(
            "Filters to apply to the library visible in Android Auto. Only the first 108 items will be shown."),
        "settingsDefaultFilters":
            MessageLookupByLibrary.simpleMessage("Default Filters"),
        "settingsDefaultGrid":
            MessageLookupByLibrary.simpleMessage("Default grid view"),
        "settingsDefaultGridDownload":
            MessageLookupByLibrary.simpleMessage("Download tab"),
        "settingsDefaultGridFavorite":
            MessageLookupByLibrary.simpleMessage("Favorites tab"),
        "settingsDefaultGridPodcast":
            MessageLookupByLibrary.simpleMessage("Podcast page"),
        "settingsDefaultGridRecent":
            MessageLookupByLibrary.simpleMessage("Recent tab"),
        "settingsDiscovery": MessageLookupByLibrary.simpleMessage(
            "Reenable \"Discover Features\""),
        "settingsDiscoveryDes": MessageLookupByLibrary.simpleMessage(
            "Are you sure you want to reenable \"Discover Features\"?"),
        "settingsDownloadAskOnForbidden": MessageLookupByLibrary.simpleMessage(
            "Ask when starting download on a forbidden connection"),
        "settingsDownloadAskOnForbiddenDes": MessageLookupByLibrary.simpleMessage(
            "If approved, downloads will be temporarily allowed on all connections."),
        "settingsDownloadPosition":
            MessageLookupByLibrary.simpleMessage("Download position"),
        "settingsDownloads": MessageLookupByLibrary.simpleMessage("Downloads"),
        "settingsDownloadsDes": MessageLookupByLibrary.simpleMessage(
            "Auto download, auto delete and forbidden connections"),
        "settingsEnableSyncing":
            MessageLookupByLibrary.simpleMessage("Enable auto synchronisation"),
        "settingsEnableSyncingDes": MessageLookupByLibrary.simpleMessage(
            "Refresh all podcasts in the background to get latest episodes."),
        "settingsEpisodeManagement":
            MessageLookupByLibrary.simpleMessage("Episode Management"),
        "settingsExportDes": MessageLookupByLibrary.simpleMessage(
            "Export, import and reset app settings."),
        "settingsFastForwardSec":
            MessageLookupByLibrary.simpleMessage("Fast forward seconds"),
        "settingsFastForwardSecDes": MessageLookupByLibrary.simpleMessage(
            "Change the fast forward seconds in player"),
        "settingsFeedback": MessageLookupByLibrary.simpleMessage("Feedback"),
        "settingsFeedbackDes":
            MessageLookupByLibrary.simpleMessage("Bugs and feature requests"),
        "settingsForbiddenDownloadConnections":
            MessageLookupByLibrary.simpleMessage(
                "Forbidden download connections"),
        "settingsForbiddenDownloadConnectionsDes":
            MessageLookupByLibrary.simpleMessage(
                "Downloads will be forbidden on selected connections based on the rules above."),
        "settingsGeneral": MessageLookupByLibrary.simpleMessage("General"),
        "settingsHistory": MessageLookupByLibrary.simpleMessage("History"),
        "settingsHistoryDes":
            MessageLookupByLibrary.simpleMessage("Listen data"),
        "settingsHomeTabAdd":
            MessageLookupByLibrary.simpleMessage("Add new tab"),
        "settingsHomeTabName": MessageLookupByLibrary.simpleMessage("Tab name"),
        "settingsHomeTabNew": MessageLookupByLibrary.simpleMessage("New tab"),
        "settingsHomeTabs": MessageLookupByLibrary.simpleMessage("Home tabs"),
        "settingsInfo": MessageLookupByLibrary.simpleMessage("Info"),
        "settingsInterface": MessageLookupByLibrary.simpleMessage("Interface"),
        "settingsInterfaceDes":
            MessageLookupByLibrary.simpleMessage("Ui defaults"),
        "settingsLanguage": MessageLookupByLibrary.simpleMessage("Language"),
        "settingsLegacy":
            MessageLookupByLibrary.simpleMessage("Settings (Legacy)"),
        "settingsLibraries": MessageLookupByLibrary.simpleMessage("Libraries"),
        "settingsLibrariesDes": MessageLookupByLibrary.simpleMessage(
            "Open source libraries used in this app"),
        "settingsLookAndFeel":
            MessageLookupByLibrary.simpleMessage("Look and Feel"),
        "settingsLookAndFeelDes":
            MessageLookupByLibrary.simpleMessage("Colors, fonts and haptics"),
        "settingsManageDownload":
            MessageLookupByLibrary.simpleMessage("Manage downloads"),
        "settingsManageDownloadDes": MessageLookupByLibrary.simpleMessage(
            "Manage downloaded audio files"),
        "settingsMarkListenedSkip":
            MessageLookupByLibrary.simpleMessage("Mark skipped as played"),
        "settingsMarkListenedSkipDes": MessageLookupByLibrary.simpleMessage(
            "Mark episode as played when skipping to next."),
        "settingsMediaControls": MessageLookupByLibrary.simpleMessage(
            "Notification panel media controls"),
        "settingsMediaControlsDes": MessageLookupByLibrary.simpleMessage(
            "The placement of the buttons may differ between devices, Android versions and selections of buttons."),
        "settingsMenuAutoPlay":
            MessageLookupByLibrary.simpleMessage("Auto play next"),
        "settingsNetworkCellular": MessageLookupByLibrary.simpleMessage(
            "Ask before using cellular data"),
        "settingsNetworkCellularDes": MessageLookupByLibrary.simpleMessage(
            "Ask to confirm when using cellular data to download episodes"),
        "settingsNewEpisodes":
            MessageLookupByLibrary.simpleMessage("New Episodes"),
        "settingsNewEpisodesDes":
            MessageLookupByLibrary.simpleMessage("New episode criteria."),
        "settingsNewEpisodesMark":
            MessageLookupByLibrary.simpleMessage("Mark new episodes"),
        "settingsNewEpisodesMarkAge":
            MessageLookupByLibrary.simpleMessage("Maximum Age"),
        "settingsNewEpisodesMarkAgeDes": MessageLookupByLibrary.simpleMessage(
            "Publish date is newer than..."),
        "settingsNewEpisodesMarkDes": MessageLookupByLibrary.simpleMessage(
            "Criteria for marking episodes as new after sync."),
        "settingsNewEpisodesMarkDuplicate":
            MessageLookupByLibrary.simpleMessage("Duplicate"),
        "settingsNewEpisodesMarkDuplicateDes":
            MessageLookupByLibrary.simpleMessage(
                "Duplicate episode versions can be marked as new."),
        "settingsNewEpisodesMarkNewPodcast":
            MessageLookupByLibrary.simpleMessage("New Podcast"),
        "settingsNewEpisodesMarkNewPodcastDes":
            MessageLookupByLibrary.simpleMessage(
                "Episodes can be marked as new on initial podcast subscription."),
        "settingsNewEpisodesMarkUnseen":
            MessageLookupByLibrary.simpleMessage("Unseen"),
        "settingsNewEpisodesMarkUnseenDes":
            MessageLookupByLibrary.simpleMessage(
                "Episode was not in the database before sync."),
        "settingsNewEpisodesUnmark":
            MessageLookupByLibrary.simpleMessage("Unmark new episodes"),
        "settingsNewEpisodesUnmarkAge":
            MessageLookupByLibrary.simpleMessage("Minimum Age"),
        "settingsNewEpisodesUnmarkAgeDes": MessageLookupByLibrary.simpleMessage(
            "Publish date is older than..."),
        "settingsNewEpisodesUnmarkDes": MessageLookupByLibrary.simpleMessage(
            "Criteria for automatically removing the new mark from episodes."),
        "settingsNewEpisodesUnmarkInteracted":
            MessageLookupByLibrary.simpleMessage("Interacted"),
        "settingsNewEpisodesUnmarkInteractedDes":
            MessageLookupByLibrary.simpleMessage(
                "Episode details were opened or episode was selected."),
        "settingsNewEpisodesUnmarkPlayed":
            MessageLookupByLibrary.simpleMessage("Played"),
        "settingsNewEpisodesUnmarkPlayedDes":
            MessageLookupByLibrary.simpleMessage("Episode was played."),
        "settingsNewEpisodesUnmarkWaitSync":
            MessageLookupByLibrary.simpleMessage("Wait until next sync"),
        "settingsNewEpisodesUnmarkWaitSyncDes":
            MessageLookupByLibrary.simpleMessage(
                "Only remove new marks during sync."),
        "settingsPauseDownloadOnForbiddenConnected":
            MessageLookupByLibrary.simpleMessage(
                "Pause and resume downloads based on connectivity"),
        "settingsPauseDownloadOnForbiddenConnectedDes":
            MessageLookupByLibrary.simpleMessage(
                "All downloads will be paused if the connection changes to a forbidden one. All paused downloads will be resumed when the forbidden connection ends."),
        "settingsPlayback": MessageLookupByLibrary.simpleMessage("Playback"),
        "settingsPlaybackDes":
            MessageLookupByLibrary.simpleMessage("Playback behavior"),
        "settingsPlayerState":
            MessageLookupByLibrary.simpleMessage("Audio Player State"),
        "settingsPopupMenu":
            MessageLookupByLibrary.simpleMessage("Episodes popup menu"),
        "settingsPopupMenuDes": MessageLookupByLibrary.simpleMessage(
            "Change the popup menu of episodes"),
        "settingsPrefrence": MessageLookupByLibrary.simpleMessage("Preference"),
        "settingsRequirements":
            MessageLookupByLibrary.simpleMessage("Requirements"),
        "settingsRequirementsAll": MessageLookupByLibrary.simpleMessage("All"),
        "settingsRequirementsAny": MessageLookupByLibrary.simpleMessage("Any"),
        "settingsRequirementsDes": MessageLookupByLibrary.simpleMessage(
            "In addition to the above, require all or any of the below."),
        "settingsReset": MessageLookupByLibrary.simpleMessage("Reset"),
        "settingsRewindSec":
            MessageLookupByLibrary.simpleMessage("Rewind seconds"),
        "settingsRewindSecDes": MessageLookupByLibrary.simpleMessage(
            "Change the rewind seconds in player"),
        "settingsSTAuto":
            MessageLookupByLibrary.simpleMessage("Auto turn on sleep timer"),
        "settingsSTAutoDes": MessageLookupByLibrary.simpleMessage(
            "Auto start sleep timer at scheduled time."),
        "settingsSTDefaultTime":
            MessageLookupByLibrary.simpleMessage("Default time"),
        "settingsSTDefautTimeDes": MessageLookupByLibrary.simpleMessage(
            "Default waiting time for sleep timer."),
        "settingsSTMode":
            MessageLookupByLibrary.simpleMessage("Auto sleep timer mode"),
        "settingsSTWaitEpisodeEnd":
            MessageLookupByLibrary.simpleMessage("Play until end"),
        "settingsSTWaitEpisodeEndDes": MessageLookupByLibrary.simpleMessage(
            "Wait until the end of the playing episode to stop playback when sleep timer expires."),
        "settingsSearchApi":
            MessageLookupByLibrary.simpleMessage("Default search api"),
        "settingsSearchEngine":
            MessageLookupByLibrary.simpleMessage("Default web search engine"),
        "settingsSearchMode":
            MessageLookupByLibrary.simpleMessage("Search web by default"),
        "settingsSpeeds": MessageLookupByLibrary.simpleMessage("Speeds"),
        "settingsSpeedsDes": MessageLookupByLibrary.simpleMessage(
            "Customize the speeds available"),
        "settingsSyncing": MessageLookupByLibrary.simpleMessage("Syncing"),
        "settingsSyncingDes": MessageLookupByLibrary.simpleMessage(
            "Refresh podcasts in the background"),
        "settingsSyncingInterval":
            MessageLookupByLibrary.simpleMessage("Syncing interval"),
        "settingsTapToOpenPopupMenu":
            MessageLookupByLibrary.simpleMessage("Tap to open popup menu"),
        "settingsTapToOpenPopupMenuDes": MessageLookupByLibrary.simpleMessage(
            "You need to long press to open episode page"),
        "settingsTheme": MessageLookupByLibrary.simpleMessage("Theme"),
        "settingsTrueBlack": MessageLookupByLibrary.simpleMessage("True Black"),
        "settingsTrueBlackDes": MessageLookupByLibrary.simpleMessage(
            "Black surfaces on dark theme"),
        "settingsUseSystemAccentColor":
            MessageLookupByLibrary.simpleMessage("Use system accent color"),
        "share": MessageLookupByLibrary.simpleMessage("Share"),
        "showNotesFonts":
            MessageLookupByLibrary.simpleMessage("Show notes font"),
        "size": MessageLookupByLibrary.simpleMessage("Size"),
        "skipSecondsAtEnd":
            MessageLookupByLibrary.simpleMessage("Skip seconds at end"),
        "skipSecondsAtStart":
            MessageLookupByLibrary.simpleMessage("Skip seconds at start"),
        "skipSilence": MessageLookupByLibrary.simpleMessage("Skip silence"),
        "skipToNext": MessageLookupByLibrary.simpleMessage("Skip to next"),
        "skipToPrevious":
            MessageLookupByLibrary.simpleMessage("Skip to Previous"),
        "sleepTimer": MessageLookupByLibrary.simpleMessage("Sleep timer"),
        "sleepTimerCancel":
            MessageLookupByLibrary.simpleMessage("Cancel timer"),
        "sleepTimerExpireAt": MessageLookupByLibrary.simpleMessage("Expire At"),
        "sleepTimerStart": MessageLookupByLibrary.simpleMessage("Start timer"),
        "sleepTimerWait":
            MessageLookupByLibrary.simpleMessage("Waiting for episode to end"),
        "sleepTimerWaitFor":
            MessageLookupByLibrary.simpleMessage("Wait For (Minutes)"),
        "sortBy": MessageLookupByLibrary.simpleMessage("Sort By"),
        "sortOrder": MessageLookupByLibrary.simpleMessage("Sort Order"),
        "status": MessageLookupByLibrary.simpleMessage("Status"),
        "statusAuthError":
            MessageLookupByLibrary.simpleMessage("Authentication error"),
        "statusFail": MessageLookupByLibrary.simpleMessage("Failed"),
        "statusSuccess": MessageLookupByLibrary.simpleMessage("Successful"),
        "stop": MessageLookupByLibrary.simpleMessage("Stop"),
        "subscribe": MessageLookupByLibrary.simpleMessage("Subscribe"),
        "subscribeExportDes": MessageLookupByLibrary.simpleMessage(
            "Export OPML file of all podcasts"),
        "subscribed": MessageLookupByLibrary.simpleMessage("Subscribed"),
        "sync": MessageLookupByLibrary.simpleMessage("Sync"),
        "syncFinished": MessageLookupByLibrary.simpleMessage("Sync finished"),
        "syncNow": MessageLookupByLibrary.simpleMessage("Sync now"),
        "syncStarted": MessageLookupByLibrary.simpleMessage("Sync started"),
        "systemDefault": MessageLookupByLibrary.simpleMessage("System default"),
        "timeLastPlayed": m27,
        "timeLeft": m28,
        "to": m29,
        "toastAddPlaylist":
            MessageLookupByLibrary.simpleMessage("Added to playlist"),
        "toastDiscovery": MessageLookupByLibrary.simpleMessage(
            "Discovery feature reenabled, please reopen the app"),
        "toastFileError": MessageLookupByLibrary.simpleMessage(
            "File error, subscribing failed"),
        "toastFileNotValid":
            MessageLookupByLibrary.simpleMessage("File not valid"),
        "toastHomeGroupNotSupport":
            MessageLookupByLibrary.simpleMessage("Home group is not supported"),
        "toastImportSettingsSuccess": MessageLookupByLibrary.simpleMessage(
            "Settings imported successfully"),
        "toastOneGroup":
            MessageLookupByLibrary.simpleMessage("Select at least one group"),
        "toastPodcastRecovering": MessageLookupByLibrary.simpleMessage(
            "Recovering, wait for a moment"),
        "toastReadFile":
            MessageLookupByLibrary.simpleMessage("File read successfully"),
        "toastRecoverFailed":
            MessageLookupByLibrary.simpleMessage("Podcast recover failed"),
        "toastRemovePlaylist": MessageLookupByLibrary.simpleMessage(
            "Episode removed from playlist"),
        "toastSettingSaved":
            MessageLookupByLibrary.simpleMessage("Settings saved"),
        "toastTimeEqualEnd":
            MessageLookupByLibrary.simpleMessage("Time is equal to end time"),
        "toastTimeEqualStart":
            MessageLookupByLibrary.simpleMessage("Time is equal to start time"),
        "translators": MessageLookupByLibrary.simpleMessage("Translators"),
        "understood": MessageLookupByLibrary.simpleMessage("Understood"),
        "undo": MessageLookupByLibrary.simpleMessage("UNDO"),
        "unlike": MessageLookupByLibrary.simpleMessage("Unlike"),
        "unliked": MessageLookupByLibrary.simpleMessage(
            "Episode removed from favorites"),
        "unsupported": MessageLookupByLibrary.simpleMessage("Unsupported"),
        "updateDate": MessageLookupByLibrary.simpleMessage("Update date"),
        "updateEpisodesCount": m30,
        "updateFailed": MessageLookupByLibrary.simpleMessage(
            "Update failed, network error"),
        "username": MessageLookupByLibrary.simpleMessage("Username"),
        "usernameRequired":
            MessageLookupByLibrary.simpleMessage("Username required"),
        "version": m31,
        "vpn": MessageLookupByLibrary.simpleMessage("VPN"),
        "weeksCount": m37,
        "welcome": MessageLookupByLibrary.simpleMessage("Welcome to Tsacdop!"),
        "wifi": MessageLookupByLibrary.simpleMessage("Wi-Fi"),
        "yearsCount": m38
      };
}
