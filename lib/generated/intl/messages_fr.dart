// DO NOT EDIT. This is code generated via package:intl/generate_localized.dart
// This is a library that provides messages for a fr locale. All the
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
  String get localeName => 'fr';

  static String m0(groupName, count) =>
      "${Intl.plural(count, zero: '', one: '${count} épisode de ${groupName} ajouté à la playlist.', other: '${count} épisodes de ${groupName} ajoutés à la playlist.')}";

  static String m1(count) =>
      "${Intl.plural(count, zero: '', one: '${count} épisode ajouté à la playlist.', other: '${count} épisodes ajoutés à la playlist.')}";

  static String m2(count) =>
      "${Intl.plural(count, zero: 'Aujourd\'hui', one: 'Il y a ${count} jour', other: 'Il y a ${count} jours')}";

  static String m3(count) =>
      "${Intl.plural(count, zero: 'Jamais', one: '${count} jour', other: '${count} jours')}";

  static String m4(count) =>
      "${Intl.plural(count, zero: '', one: 'Épisode', other: 'Épisodes ')}";

  static String m5(type) => "";

  static String m6(time) => "De ${time}";

  static String m7(icon) => "";

  static String m8(count) =>
      "${Intl.plural(count, zero: 'Groupe', one: 'Groupe', other: 'Groupes')}";

  static String m9(host) => "Hébergé par ${host}";

  static String m10(count) =>
      "${Intl.plural(count, zero: 'A l\'instant', one: 'Il y a ${count} heure', other: 'Il y a ${count} heures')}";

  static String m11(count) =>
      "${Intl.plural(count, zero: '0 heure', one: '${count} heure', other: '${count} heures')}";

  static String m12(service) => "Integrate with ${service}";

  static String m13(filePath) => "";

  static String m14(userName) => "Logged in as ${userName}";

  static String m15(count) =>
      "${Intl.plural(count, zero: 'A l\'instant', one: 'Il y a ${count} minute', other: 'Il y a ${count} minutes')}";

  static String m16(count) =>
      "${Intl.plural(count, zero: '0 min', one: '${count} min', other: '${count} mins')}";

  static String m17(count) => "";

  static String m18(title) => "Accès aux données ${title} ";

  static String m19(title) => "Échec de l’abonnement, erreur réseau ${title} ";

  static String m20(title) => "Abonnement en cours";

  static String m21(title) =>
      "Échec de l’abonnement, le podcast existe déjà ${title}";

  static String m22(title) => "Abonnement réussi.";

  static String m23(title) => "Mise à jour ${title}";

  static String m24(title) => "Échec de la mise à jour ${title}";

  static String m25(count) =>
      "${Intl.plural(count, zero: '', one: 'Podcast', other: 'Podcasts')}";

  static String m26(date) => "Publié le ${date}";

  static String m27(date) => "Supprimé le ${date}";

  static String m28(start, end) => "";

  static String m29(count) =>
      "${Intl.plural(count, zero: '0 sec', one: '${count} sec', other: '${count} sec')}";

  static String m30(count) =>
      "${Intl.plural(count, zero: 'A l\'instant', one: 'Il y a ${count} seconde', other: 'Il y a ${count} secondes')}";

  static String m31(count) => "";

  static String m32(time) => "Dernière écoute à ${time}";

  static String m33(time) => "${time} Restant";

  static String m34(time) => "à ${time}";

  static String m35(count) =>
      "${Intl.plural(count, zero: 'Aucune mise à jour.', one: 'Mise à jour d\'${count} épisode.', other: 'Mise à jour de ${count} épisodes.')}";

  static String m36(version) => "Version : ${version}";

  static String m37(count) => "";

  static String m38(count) => "";

  final messages = _notInlinedMessages(_notInlinedMessages);
  static Map<String, Function> _notInlinedMessages(_) => <String, Function>{
    "aboutDes": MessageLookupByLibrary.simpleMessage(""),
    "add": MessageLookupByLibrary.simpleMessage("Ajouter"),
    "addEpisodeGroup": m0,
    "addNewEpisodeAll": m1,
    "addNewEpisodeTooltip": MessageLookupByLibrary.simpleMessage(
      "Ajouter de nouveaux épisodes à la playlist.",
    ),
    "addSomeGroups": MessageLookupByLibrary.simpleMessage(
      "Ajouter des groupes",
    ),
    "after": MessageLookupByLibrary.simpleMessage(""),
    "all": MessageLookupByLibrary.simpleMessage("Tout"),
    "apiSearch": MessageLookupByLibrary.simpleMessage(""),
    "autoDownload": MessageLookupByLibrary.simpleMessage("Automatisation"),
    "back": MessageLookupByLibrary.simpleMessage("Retour"),
    "before": MessageLookupByLibrary.simpleMessage(""),
    "between": MessageLookupByLibrary.simpleMessage(""),
    "boostVolume": MessageLookupByLibrary.simpleMessage("Booster le volume"),
    "buffering": MessageLookupByLibrary.simpleMessage("Buffering"),
    "cancel": MessageLookupByLibrary.simpleMessage("ANNULER"),
    "capitalDefault": MessageLookupByLibrary.simpleMessage(""),
    "cellularConfirm": MessageLookupByLibrary.simpleMessage(
      "Avertissement utilisation des données mobiles",
    ),
    "cellularConfirmDes": MessageLookupByLibrary.simpleMessage(
      "Êtes-vous sûr d\'autoriser l\'utilisation des données mobiles ?",
    ),
    "changeLayout": MessageLookupByLibrary.simpleMessage(
      "Modifier l\'interface",
    ),
    "changelog": MessageLookupByLibrary.simpleMessage("Changelog"),
    "chooseA": MessageLookupByLibrary.simpleMessage("Choisir un"),
    "clear": MessageLookupByLibrary.simpleMessage("Effacer"),
    "clearAll": MessageLookupByLibrary.simpleMessage(""),
    "close": MessageLookupByLibrary.simpleMessage(""),
    "color": MessageLookupByLibrary.simpleMessage("Couleur"),
    "confirm": MessageLookupByLibrary.simpleMessage("CONFIRMER"),
    "confirmation": MessageLookupByLibrary.simpleMessage(""),
    "contribute": MessageLookupByLibrary.simpleMessage(""),
    "createNewPlaylist": MessageLookupByLibrary.simpleMessage(""),
    "darkMode": MessageLookupByLibrary.simpleMessage("Mode sombre"),
    "daysAgo": m2,
    "daysCount": m3,
    "defaultQueueReminder": MessageLookupByLibrary.simpleMessage(""),
    "defaultSearchEngine": MessageLookupByLibrary.simpleMessage(
      "Default podcast search engine",
    ),
    "defaultSearchEngineDes": MessageLookupByLibrary.simpleMessage(
      "Choose the default podcast search engine",
    ),
    "delete": MessageLookupByLibrary.simpleMessage("Effacer"),
    "deleted": MessageLookupByLibrary.simpleMessage(""),
    "deletedEpisodeDesc": MessageLookupByLibrary.simpleMessage(""),
    "deletedPodcastDesc": MessageLookupByLibrary.simpleMessage(""),
    "deselectAll": MessageLookupByLibrary.simpleMessage(""),
    "details": MessageLookupByLibrary.simpleMessage(""),
    "developer": MessageLookupByLibrary.simpleMessage("Développeur"),
    "developerOriginal": MessageLookupByLibrary.simpleMessage(""),
    "deviceStorage": MessageLookupByLibrary.simpleMessage(""),
    "disabled": MessageLookupByLibrary.simpleMessage(""),
    "dismiss": MessageLookupByLibrary.simpleMessage("Passer"),
    "displayVersion": MessageLookupByLibrary.simpleMessage(""),
    "done": MessageLookupByLibrary.simpleMessage("Fait"),
    "download": MessageLookupByLibrary.simpleMessage("Téléchargés"),
    "downloadDate": MessageLookupByLibrary.simpleMessage(""),
    "downloadRemovedToast": MessageLookupByLibrary.simpleMessage(
      "Download removed",
    ),
    "downloadStart": MessageLookupByLibrary.simpleMessage("Downloading"),
    "downloaded": MessageLookupByLibrary.simpleMessage("Téléchargés"),
    "downloading": MessageLookupByLibrary.simpleMessage(""),
    "duration": MessageLookupByLibrary.simpleMessage(""),
    "editGroupName": MessageLookupByLibrary.simpleMessage(
      "Modifier le nom du groupe",
    ),
    "endOfEpisode": MessageLookupByLibrary.simpleMessage("Fin de l\'épisode"),
    "episode": m4,
    "fastForward": MessageLookupByLibrary.simpleMessage("Fast forward"),
    "fastRewind": MessageLookupByLibrary.simpleMessage("Fast rewind"),
    "featureDiscoveryEditGroup": MessageLookupByLibrary.simpleMessage(
      "Gestion des groupes",
    ),
    "featureDiscoveryEditGroupDes": MessageLookupByLibrary.simpleMessage(
      "Ici vous pouvez supprimer ou modifier le nom des groupes, seul le groupe Home ne peut être édité.",
    ),
    "featureDiscoveryEpisode": MessageLookupByLibrary.simpleMessage(
      "Vue épisode",
    ),
    "featureDiscoveryEpisodeDes": MessageLookupByLibrary.simpleMessage(
      "Vous pouvez effectuer un appui long pour jouer un épisode ou l\'ajouter à la playlist.",
    ),
    "featureDiscoveryEpisodeTitle": MessageLookupByLibrary.simpleMessage(
      "Effectuez un appui long pour lancer un épisode",
    ),
    "featureDiscoveryGroup": MessageLookupByLibrary.simpleMessage(
      "Appuyez ici pour créer un groupe",
    ),
    "featureDiscoveryGroupDes": MessageLookupByLibrary.simpleMessage(
      "Pour les nouveaux podcasts le groupe par défaut est Home. Vous pouvez créer de nouveaux groupes et y déplacer vos podcasts. Un podcast peut être associé à plusieurs groupes.",
    ),
    "featureDiscoveryGroupPodcast": MessageLookupByLibrary.simpleMessage(
      "Classement des podcasts",
    ),
    "featureDiscoveryGroupPodcastDes": MessageLookupByLibrary.simpleMessage(
      "Appuyez ici pour accéder à plus d\'options, un appui long permet de classer les podcasts d\'un groupe.",
    ),
    "featureDiscoveryOMPL": MessageLookupByLibrary.simpleMessage(
      "Appuyez ici pour importer un fichier OPML",
    ),
    "featureDiscoveryOMPLDes": MessageLookupByLibrary.simpleMessage(
      "Vous pouvez importer un fichier OPML, accéder aux paramètres ou actualiser tous les podcasts.",
    ),
    "featureDiscoveryPlaylist": MessageLookupByLibrary.simpleMessage(
      "Appuyez ici pour ouvrir la playlist",
    ),
    "featureDiscoveryPlaylistDes": MessageLookupByLibrary.simpleMessage(
      "Ajoutez des épisodes dans la playlist. Ils seront automatiquement retirés une fois écoutés.",
    ),
    "featureDiscoveryPodcast": MessageLookupByLibrary.simpleMessage(
      "Vue podcasts",
    ),
    "featureDiscoveryPodcastDes": MessageLookupByLibrary.simpleMessage(
      "Appuyez sur Tout Voir pour ajouter des groupes et gérer les podcasts.",
    ),
    "featureDiscoveryPodcastTitle": MessageLookupByLibrary.simpleMessage(
      "Effectuez un défilement vertical pour changer de groupe.",
    ),
    "featureDiscoverySearch": MessageLookupByLibrary.simpleMessage(
      "Appuyez ici pour rechercher un podcast",
    ),
    "featureDiscoverySearchDes": MessageLookupByLibrary.simpleMessage(
      "Pour trouver vos podcasts vous pouvez effectuer une recherche par titres, mots clés ou liens RSS.",
    ),
    "feedbackEmail": MessageLookupByLibrary.simpleMessage("Contact"),
    "feedbackGithub": MessageLookupByLibrary.simpleMessage("GitHub"),
    "feedbackPlay": MessageLookupByLibrary.simpleMessage("PlayStore"),
    "feedbackTelegram": MessageLookupByLibrary.simpleMessage("Telegram"),
    "filter": MessageLookupByLibrary.simpleMessage("Filtrer"),
    "filterType": m5,
    "fontStyle": MessageLookupByLibrary.simpleMessage("Font style"),
    "fonts": MessageLookupByLibrary.simpleMessage("Polices"),
    "forward": MessageLookupByLibrary.simpleMessage(""),
    "from": m6,
    "getStarted": MessageLookupByLibrary.simpleMessage(""),
    "getStartedDes": m7,
    "globallyDisabled": MessageLookupByLibrary.simpleMessage(""),
    "goodNight": MessageLookupByLibrary.simpleMessage("Bonne nuit"),
    "gpodderLoginDes": MessageLookupByLibrary.simpleMessage(
      "Congratulations! You  have linked gpodder.net account successfully. Tsacdop will automatically sync subscriptions on your device with your gpodder.net account.",
    ),
    "groupExisted": MessageLookupByLibrary.simpleMessage(
      "Ce groupe existe déjà",
    ),
    "groupRemoveConfirm": MessageLookupByLibrary.simpleMessage(
      "Êtes-vous sûr de vouloir supprimer ce groupe ? Les podcasts seront déplacés vers le groupe Home.",
    ),
    "groups": m8,
    "haptics": MessageLookupByLibrary.simpleMessage(""),
    "hapticsDes": MessageLookupByLibrary.simpleMessage(""),
    "hideListenedSetting": MessageLookupByLibrary.simpleMessage(
      "Hide listened",
    ),
    "hidePodcastDiscovery": MessageLookupByLibrary.simpleMessage(
      "Hide podcast discovery",
    ),
    "hidePodcastDiscoveryDes": MessageLookupByLibrary.simpleMessage(
      "Hide podcast discovery in search page",
    ),
    "homeGroupsSeeAll": MessageLookupByLibrary.simpleMessage("Tout Voir"),
    "homeMenuPlaylist": MessageLookupByLibrary.simpleMessage("Playlist"),
    "homeSubMenuSortBy": MessageLookupByLibrary.simpleMessage("Classé par"),
    "homeTabMenuFavotite": MessageLookupByLibrary.simpleMessage("Favoris"),
    "homeTabMenuRecent": MessageLookupByLibrary.simpleMessage("Récents"),
    "homeToprightMenuAbout": MessageLookupByLibrary.simpleMessage("À propos"),
    "homeToprightMenuImportOMPL": MessageLookupByLibrary.simpleMessage(
      "Importer un fichier OPML",
    ),
    "homeToprightMenuRefreshAll": MessageLookupByLibrary.simpleMessage(
      "Tout actualiser",
    ),
    "hostedOn": m9,
    "hoursAgo": m10,
    "hoursCount": m11,
    "import": MessageLookupByLibrary.simpleMessage("Importer"),
    "importingOpml": MessageLookupByLibrary.simpleMessage(""),
    "interaction": MessageLookupByLibrary.simpleMessage(""),
    "intergateWith": m12,
    "introFourthPage": MessageLookupByLibrary.simpleMessage(
      "Un appui long sur un épisode lance les actions rapides.",
    ),
    "introSecondPage": MessageLookupByLibrary.simpleMessage(
      "S\'abonner aux podcasts via la section recherche ou un fichier OPML.",
    ),
    "introThirdPage": MessageLookupByLibrary.simpleMessage(
      "Vous pouvez créer des groupes de podcasts.",
    ),
    "invalidName": MessageLookupByLibrary.simpleMessage("Invalid username"),
    "keepAndroidOpen": MessageLookupByLibrary.simpleMessage(""),
    "keepAndroidOpenDes": MessageLookupByLibrary.simpleMessage(""),
    "lastUpdate": MessageLookupByLibrary.simpleMessage("Last update"),
    "later": MessageLookupByLibrary.simpleMessage("Plus tard"),
    "lightMode": MessageLookupByLibrary.simpleMessage("Mode clair"),
    "like": MessageLookupByLibrary.simpleMessage("Like"),
    "likeDate": MessageLookupByLibrary.simpleMessage("Date du like"),
    "liked": MessageLookupByLibrary.simpleMessage("Liké"),
    "listen": MessageLookupByLibrary.simpleMessage("Écoutés"),
    "listened": MessageLookupByLibrary.simpleMessage("Écouté "),
    "loadAllSelected": MessageLookupByLibrary.simpleMessage(""),
    "loadMore": MessageLookupByLibrary.simpleMessage("Voir plus"),
    "loading": MessageLookupByLibrary.simpleMessage(""),
    "localEpisodeDescription": m13,
    "localFolder": MessageLookupByLibrary.simpleMessage(""),
    "localFolderDescription": MessageLookupByLibrary.simpleMessage(""),
    "localizationWeblate": MessageLookupByLibrary.simpleMessage(""),
    "loggedInAs": m14,
    "login": MessageLookupByLibrary.simpleMessage("Login"),
    "loginFailed": MessageLookupByLibrary.simpleMessage("Login failed"),
    "logout": MessageLookupByLibrary.simpleMessage("Logout"),
    "mark": MessageLookupByLibrary.simpleMessage("✓"),
    "markConfirm": MessageLookupByLibrary.simpleMessage("Marquage effectué"),
    "markConfirmContent": MessageLookupByLibrary.simpleMessage(
      "Marquer tous les épisodes comme lus ?",
    ),
    "markListened": MessageLookupByLibrary.simpleMessage("Marquage"),
    "markNotListened": MessageLookupByLibrary.simpleMessage(
      "Mark not listened",
    ),
    "menu": MessageLookupByLibrary.simpleMessage("Menu"),
    "menuAllPodcasts": MessageLookupByLibrary.simpleMessage(
      "Tous les podcasts",
    ),
    "menuMarkAllListened": MessageLookupByLibrary.simpleMessage(
      "Marquer comme tous lu",
    ),
    "menuViewRSS": MessageLookupByLibrary.simpleMessage("Accéder au flux RSS"),
    "menuVisitSite": MessageLookupByLibrary.simpleMessage("Accéder au site"),
    "minsAgo": m15,
    "minsCount": m16,
    "mobileData": MessageLookupByLibrary.simpleMessage(""),
    "monthsCount": m17,
    "moreOptions": MessageLookupByLibrary.simpleMessage(""),
    "network": MessageLookupByLibrary.simpleMessage("Réseau"),
    "networkErrorDNS": MessageLookupByLibrary.simpleMessage(""),
    "neverAutoUpdate": MessageLookupByLibrary.simpleMessage(
      "Turn off auto update",
    ),
    "neverAutoUpdateDes": MessageLookupByLibrary.simpleMessage(""),
    "newGroup": MessageLookupByLibrary.simpleMessage("Créer un nouveau groupe"),
    "newPlain": MessageLookupByLibrary.simpleMessage(""),
    "newPlaylist": MessageLookupByLibrary.simpleMessage(""),
    "newestFirst": MessageLookupByLibrary.simpleMessage(
      "Le plus récent en premier",
    ),
    "next": MessageLookupByLibrary.simpleMessage("Suivant"),
    "noEpisodesFound": MessageLookupByLibrary.simpleMessage(""),
    "noPodcastGroup": MessageLookupByLibrary.simpleMessage(
      "Ce groupe ne contient aucun podcast",
    ),
    "noShownote": MessageLookupByLibrary.simpleMessage(
      "Notes de l\'épisode manquantes.",
    ),
    "none": MessageLookupByLibrary.simpleMessage(""),
    "notificaitonFatch": m18,
    "notificationAddingGroups": MessageLookupByLibrary.simpleMessage(""),
    "notificationNetworkError": m19,
    "notificationSubscribe": m20,
    "notificationSubscribeExisted": m21,
    "notificationSubscribing": MessageLookupByLibrary.simpleMessage(""),
    "notificationSuccess": m22,
    "notificationUpdate": m23,
    "notificationUpdateError": m24,
    "oldestFirst": MessageLookupByLibrary.simpleMessage(
      "Le plus ancien en premier",
    ),
    "opmlFile": MessageLookupByLibrary.simpleMessage(""),
    "passwdRequired": MessageLookupByLibrary.simpleMessage("Password required"),
    "password": MessageLookupByLibrary.simpleMessage("Password"),
    "pause": MessageLookupByLibrary.simpleMessage("Pause"),
    "play": MessageLookupByLibrary.simpleMessage("Lecture"),
    "playNext": MessageLookupByLibrary.simpleMessage("Play next"),
    "playNextDes": MessageLookupByLibrary.simpleMessage(
      "Add episode to top of the playlist",
    ),
    "playback": MessageLookupByLibrary.simpleMessage("Commandes du lecteur"),
    "player": MessageLookupByLibrary.simpleMessage("Player"),
    "playerHeightMed": MessageLookupByLibrary.simpleMessage("Moyen"),
    "playerHeightShort": MessageLookupByLibrary.simpleMessage("Petit"),
    "playerHeightTall": MessageLookupByLibrary.simpleMessage("Grand"),
    "playing": MessageLookupByLibrary.simpleMessage("En cours"),
    "playlistExists": MessageLookupByLibrary.simpleMessage(""),
    "playlistNameEmpty": MessageLookupByLibrary.simpleMessage(""),
    "playlists": MessageLookupByLibrary.simpleMessage(""),
    "plugins": MessageLookupByLibrary.simpleMessage("Plugins"),
    "podcast": m25,
    "podcastList": MessageLookupByLibrary.simpleMessage(""),
    "podcastSubscribed": MessageLookupByLibrary.simpleMessage(
      "Abonné au podcast",
    ),
    "popupMenuDownloadDes": MessageLookupByLibrary.simpleMessage(
      "Télécharger l\'épisode",
    ),
    "popupMenuLaterDes": MessageLookupByLibrary.simpleMessage(
      "Ajouter à la playlist",
    ),
    "popupMenuLikeDes": MessageLookupByLibrary.simpleMessage(
      "Ajouter l\'épisode aux favoris",
    ),
    "popupMenuMarkDes": MessageLookupByLibrary.simpleMessage(
      "Marquer l\'épisode comme lu",
    ),
    "popupMenuPlayDes": MessageLookupByLibrary.simpleMessage(
      "Lancer l\'épisode",
    ),
    "privacyPolicy": MessageLookupByLibrary.simpleMessage(
      "Gestion des données",
    ),
    "publishDate": MessageLookupByLibrary.simpleMessage(""),
    "published": m26,
    "publishedDaily": MessageLookupByLibrary.simpleMessage("Quotidien"),
    "publishedMonthly": MessageLookupByLibrary.simpleMessage("Mensuel"),
    "publishedWeekly": MessageLookupByLibrary.simpleMessage("Hebdomadaire"),
    "publishedYearly": MessageLookupByLibrary.simpleMessage("Annuel"),
    "queue": MessageLookupByLibrary.simpleMessage(""),
    "random": MessageLookupByLibrary.simpleMessage(""),
    "recoverSubscribe": MessageLookupByLibrary.simpleMessage(
      "Restaurer l\'abonnement",
    ),
    "refresh": MessageLookupByLibrary.simpleMessage(""),
    "refreshArtwork": MessageLookupByLibrary.simpleMessage(
      "Mettre à jour la vignette",
    ),
    "remove": MessageLookupByLibrary.simpleMessage("Supprimer"),
    "removeConfirm": MessageLookupByLibrary.simpleMessage(
      "Confirmer la suppression",
    ),
    "removeDownload": MessageLookupByLibrary.simpleMessage(""),
    "removeNewMark": MessageLookupByLibrary.simpleMessage(""),
    "removePodcastDes": MessageLookupByLibrary.simpleMessage(
      "Êtes-vous sûr de vouloir vous désabonner ?",
    ),
    "removedAt": m27,
    "restartAppForEffect": MessageLookupByLibrary.simpleMessage(""),
    "satellite": MessageLookupByLibrary.simpleMessage(""),
    "save": MessageLookupByLibrary.simpleMessage("Sauvegarder"),
    "schedule": MessageLookupByLibrary.simpleMessage("Programmation"),
    "scheduleDisabled": MessageLookupByLibrary.simpleMessage(""),
    "scheduleTime": m28,
    "search": MessageLookupByLibrary.simpleMessage("Rechercher"),
    "searchApi": MessageLookupByLibrary.simpleMessage(""),
    "searchEngine": MessageLookupByLibrary.simpleMessage(""),
    "searchEpisode": MessageLookupByLibrary.simpleMessage(
      "Rechercher un épisode",
    ),
    "searchHelper": MessageLookupByLibrary.simpleMessage(
      "Type the podcast name, keywords or enter a feed url.",
    ),
    "searchInstructions": MessageLookupByLibrary.simpleMessage(""),
    "searchInvalidRss": MessageLookupByLibrary.simpleMessage(
      "Lien RSS invalide",
    ),
    "searchPodcast": MessageLookupByLibrary.simpleMessage(
      "Chercher un podcast",
    ),
    "searchWeb": MessageLookupByLibrary.simpleMessage(""),
    "secCount": m29,
    "secondsAgo": m30,
    "selectMode": MessageLookupByLibrary.simpleMessage(""),
    "selected": m31,
    "settingStorage": MessageLookupByLibrary.simpleMessage(
      "Espace de stockage",
    ),
    "settings": MessageLookupByLibrary.simpleMessage("Paramètres"),
    "settingsAccentColor": MessageLookupByLibrary.simpleMessage(
      "Couleur principale",
    ),
    "settingsAppIntro": MessageLookupByLibrary.simpleMessage(
      "Revoir l\'introduction",
    ),
    "settingsAppearance": MessageLookupByLibrary.simpleMessage("Apparence"),
    "settingsAppearanceDes": MessageLookupByLibrary.simpleMessage(
      "Couleurs et thèmes",
    ),
    "settingsAudioCache": MessageLookupByLibrary.simpleMessage("Cache audio"),
    "settingsAudioCacheDes": MessageLookupByLibrary.simpleMessage(
      "Taille maximum du cache audio",
    ),
    "settingsAutoDelete": MessageLookupByLibrary.simpleMessage(
      "Suppression des fichiers ",
    ),
    "settingsAutoDeleteAfterPlayed": MessageLookupByLibrary.simpleMessage(""),
    "settingsAutoDeleteAfterTime": MessageLookupByLibrary.simpleMessage(""),
    "settingsAutoDeleteAfterTimeDes": MessageLookupByLibrary.simpleMessage(""),
    "settingsAutoDeleteDes": MessageLookupByLibrary.simpleMessage(
      "30 jours par défaut",
    ),
    "settingsAutoDeleteOldestIfTotalAbove":
        MessageLookupByLibrary.simpleMessage(""),
    "settingsAutoDeleteOldestIfTotalAboveDes":
        MessageLookupByLibrary.simpleMessage(""),
    "settingsAutoDownload": MessageLookupByLibrary.simpleMessage(""),
    "settingsAutoDownloadDes": MessageLookupByLibrary.simpleMessage(""),
    "settingsAutoDownloadNewPodcast": MessageLookupByLibrary.simpleMessage(""),
    "settingsAutoDownloadNewPodcastDes": MessageLookupByLibrary.simpleMessage(
      "",
    ),
    "settingsAutoDownloadOnForbidden": MessageLookupByLibrary.simpleMessage(""),
    "settingsAutoDownloadOnForbiddenDes": MessageLookupByLibrary.simpleMessage(
      "",
    ),
    "settingsAutoPlayDes": MessageLookupByLibrary.simpleMessage(
      "Lancer automatiquement l\'épisode suivant",
    ),
    "settingsAutoSync": MessageLookupByLibrary.simpleMessage(""),
    "settingsAutoSyncDes": MessageLookupByLibrary.simpleMessage(""),
    "settingsBackup": MessageLookupByLibrary.simpleMessage("Backup"),
    "settingsBackupCategories": MessageLookupByLibrary.simpleMessage(""),
    "settingsBackupCategoriesDes": MessageLookupByLibrary.simpleMessage(""),
    "settingsBackupCategoriesImportDes": MessageLookupByLibrary.simpleMessage(
      "",
    ),
    "settingsBackupConfirmationDatabaseOverwrite":
        MessageLookupByLibrary.simpleMessage(""),
    "settingsBackupConfirmationDatabaseReset":
        MessageLookupByLibrary.simpleMessage(""),
    "settingsBackupConfirmationSettingsOverwrite":
        MessageLookupByLibrary.simpleMessage(""),
    "settingsBackupConfirmationSettingsReset":
        MessageLookupByLibrary.simpleMessage(""),
    "settingsBackupDatabase": MessageLookupByLibrary.simpleMessage(""),
    "settingsBackupDatabaseBackupFile": MessageLookupByLibrary.simpleMessage(
      "",
    ),
    "settingsBackupDatabaseBackupFileDes": MessageLookupByLibrary.simpleMessage(
      "",
    ),
    "settingsBackupDatabaseCategoriesDes": MessageLookupByLibrary.simpleMessage(
      "",
    ),
    "settingsBackupDatabaseHistory": MessageLookupByLibrary.simpleMessage(""),
    "settingsBackupDatabasePlaylists": MessageLookupByLibrary.simpleMessage(""),
    "settingsBackupDatabasePodcasts": MessageLookupByLibrary.simpleMessage(""),
    "settingsBackupDes": MessageLookupByLibrary.simpleMessage(
      "Sauvegarde des données de l\'application",
    ),
    "settingsBackupFile": MessageLookupByLibrary.simpleMessage(""),
    "settingsBackupLegacyFile": MessageLookupByLibrary.simpleMessage(""),
    "settingsBackupLegacyFileDes": MessageLookupByLibrary.simpleMessage(""),
    "settingsBackupPassword": MessageLookupByLibrary.simpleMessage(""),
    "settingsBackupPasswordDes": MessageLookupByLibrary.simpleMessage(""),
    "settingsBoostVolume": MessageLookupByLibrary.simpleMessage(
      "Booster le volume",
    ),
    "settingsBoostVolumeDes": MessageLookupByLibrary.simpleMessage(
      "Définir la puissance du volume",
    ),
    "settingsColors": MessageLookupByLibrary.simpleMessage(""),
    "settingsDefaultFilterAndroidAuto": MessageLookupByLibrary.simpleMessage(
      "",
    ),
    "settingsDefaultFilterAndroidAutoDes": MessageLookupByLibrary.simpleMessage(
      "",
    ),
    "settingsDefaultFilters": MessageLookupByLibrary.simpleMessage(""),
    "settingsDefaultGrid": MessageLookupByLibrary.simpleMessage(
      "Vue par défaut",
    ),
    "settingsDefaultGridDownload": MessageLookupByLibrary.simpleMessage(
      "Onglet Téléchargés",
    ),
    "settingsDefaultGridFavorite": MessageLookupByLibrary.simpleMessage(
      "Onglet Favoris",
    ),
    "settingsDefaultGridPodcast": MessageLookupByLibrary.simpleMessage(
      "Onglet podcasts",
    ),
    "settingsDefaultGridRecent": MessageLookupByLibrary.simpleMessage(
      "Onglet Récents",
    ),
    "settingsDiscovery": MessageLookupByLibrary.simpleMessage(
      "Revoir le tutoriel",
    ),
    "settingsDiscoveryDes": MessageLookupByLibrary.simpleMessage(""),
    "settingsDownloadAskOnForbidden": MessageLookupByLibrary.simpleMessage(""),
    "settingsDownloadAskOnForbiddenDes": MessageLookupByLibrary.simpleMessage(
      "",
    ),
    "settingsDownloadPosition": MessageLookupByLibrary.simpleMessage(
      "Download position",
    ),
    "settingsDownloads": MessageLookupByLibrary.simpleMessage(""),
    "settingsDownloadsDes": MessageLookupByLibrary.simpleMessage(""),
    "settingsEpisodeManagement": MessageLookupByLibrary.simpleMessage(""),
    "settingsExportDes": MessageLookupByLibrary.simpleMessage(
      "Exporter et importer les paramètres de l\'application.",
    ),
    "settingsFastForwardSec": MessageLookupByLibrary.simpleMessage(
      "Avance rapide",
    ),
    "settingsFastForwardSecDes": MessageLookupByLibrary.simpleMessage(
      "Saut avant",
    ),
    "settingsFeedback": MessageLookupByLibrary.simpleMessage("Feedback"),
    "settingsFeedbackDes": MessageLookupByLibrary.simpleMessage(
      "Report de bug et demande d\'ajout de fonction",
    ),
    "settingsForbiddenDownloadConnections":
        MessageLookupByLibrary.simpleMessage(""),
    "settingsForbiddenDownloadConnectionsDes":
        MessageLookupByLibrary.simpleMessage(""),
    "settingsFullStop": MessageLookupByLibrary.simpleMessage(""),
    "settingsFullStopDes": MessageLookupByLibrary.simpleMessage(""),
    "settingsGeneral": MessageLookupByLibrary.simpleMessage(""),
    "settingsHistory": MessageLookupByLibrary.simpleMessage("Historique"),
    "settingsHistoryDes": MessageLookupByLibrary.simpleMessage(
      "Gestion des données",
    ),
    "settingsHomeTabAdd": MessageLookupByLibrary.simpleMessage(""),
    "settingsHomeTabName": MessageLookupByLibrary.simpleMessage(""),
    "settingsHomeTabNew": MessageLookupByLibrary.simpleMessage(""),
    "settingsHomeTabs": MessageLookupByLibrary.simpleMessage(""),
    "settingsInfo": MessageLookupByLibrary.simpleMessage("Informations"),
    "settingsInterface": MessageLookupByLibrary.simpleMessage(
      "Interface utilisateur",
    ),
    "settingsInterfaceDes": MessageLookupByLibrary.simpleMessage(""),
    "settingsLanguage": MessageLookupByLibrary.simpleMessage(""),
    "settingsLegacy": MessageLookupByLibrary.simpleMessage(""),
    "settingsLibraries": MessageLookupByLibrary.simpleMessage("Librairies"),
    "settingsLibrariesDes": MessageLookupByLibrary.simpleMessage(
      "Librairies opensource utilisées",
    ),
    "settingsLookAndFeel": MessageLookupByLibrary.simpleMessage(""),
    "settingsLookAndFeelDes": MessageLookupByLibrary.simpleMessage(""),
    "settingsManageDownload": MessageLookupByLibrary.simpleMessage(
      "Gérer les téléchargements",
    ),
    "settingsManageDownloadDes": MessageLookupByLibrary.simpleMessage(
      "Gestion des fichiers audio téléchargés",
    ),
    "settingsManufacturerNotificationLayout":
        MessageLookupByLibrary.simpleMessage(""),
    "settingsMarkListenedSkip": MessageLookupByLibrary.simpleMessage(
      "Mark as listened when skipped",
    ),
    "settingsMarkListenedSkipDes": MessageLookupByLibrary.simpleMessage(
      "Auto mark episode as listened when it was skipped to next",
    ),
    "settingsMediaControls": MessageLookupByLibrary.simpleMessage(""),
    "settingsMediaControlsDes": MessageLookupByLibrary.simpleMessage(""),
    "settingsMenuAutoPlay": MessageLookupByLibrary.simpleMessage(
      "Lecture automatique",
    ),
    "settingsNetworkCellular": MessageLookupByLibrary.simpleMessage(
      "Utilisation du réseau mobile",
    ),
    "settingsNetworkCellularDes": MessageLookupByLibrary.simpleMessage(
      "Demander une confirmation avant de lancer un téléchargement",
    ),
    "settingsNewEpisodes": MessageLookupByLibrary.simpleMessage(""),
    "settingsNewEpisodesDes": MessageLookupByLibrary.simpleMessage(""),
    "settingsNewEpisodesMark": MessageLookupByLibrary.simpleMessage(""),
    "settingsNewEpisodesMarkAge": MessageLookupByLibrary.simpleMessage(""),
    "settingsNewEpisodesMarkAgeDes": MessageLookupByLibrary.simpleMessage(""),
    "settingsNewEpisodesMarkDes": MessageLookupByLibrary.simpleMessage(""),
    "settingsNewEpisodesMarkDuplicate": MessageLookupByLibrary.simpleMessage(
      "",
    ),
    "settingsNewEpisodesMarkDuplicateDes": MessageLookupByLibrary.simpleMessage(
      "",
    ),
    "settingsNewEpisodesMarkNewPodcast": MessageLookupByLibrary.simpleMessage(
      "",
    ),
    "settingsNewEpisodesMarkNewPodcastDes":
        MessageLookupByLibrary.simpleMessage(""),
    "settingsNewEpisodesMarkUnseen": MessageLookupByLibrary.simpleMessage(""),
    "settingsNewEpisodesMarkUnseenDes": MessageLookupByLibrary.simpleMessage(
      "",
    ),
    "settingsNewEpisodesUnmark": MessageLookupByLibrary.simpleMessage(""),
    "settingsNewEpisodesUnmarkAge": MessageLookupByLibrary.simpleMessage(""),
    "settingsNewEpisodesUnmarkAgeDes": MessageLookupByLibrary.simpleMessage(""),
    "settingsNewEpisodesUnmarkDes": MessageLookupByLibrary.simpleMessage(""),
    "settingsNewEpisodesUnmarkInteracted": MessageLookupByLibrary.simpleMessage(
      "",
    ),
    "settingsNewEpisodesUnmarkInteractedDes":
        MessageLookupByLibrary.simpleMessage(""),
    "settingsNewEpisodesUnmarkPlayed": MessageLookupByLibrary.simpleMessage(""),
    "settingsNewEpisodesUnmarkPlayedDes": MessageLookupByLibrary.simpleMessage(
      "",
    ),
    "settingsNewEpisodesUnmarkWaitSync": MessageLookupByLibrary.simpleMessage(
      "",
    ),
    "settingsNewEpisodesUnmarkWaitSyncDes":
        MessageLookupByLibrary.simpleMessage(""),
    "settingsPauseDownloadOnForbiddenConnected":
        MessageLookupByLibrary.simpleMessage(""),
    "settingsPauseDownloadOnForbiddenConnectedDes":
        MessageLookupByLibrary.simpleMessage(""),
    "settingsPlayback": MessageLookupByLibrary.simpleMessage(""),
    "settingsPlaybackDes": MessageLookupByLibrary.simpleMessage(""),
    "settingsPlayerState": MessageLookupByLibrary.simpleMessage(""),
    "settingsPopupMenu": MessageLookupByLibrary.simpleMessage(
      "Menu popup des épisodes",
    ),
    "settingsPopupMenuDes": MessageLookupByLibrary.simpleMessage(
      "Configuration du menu popup",
    ),
    "settingsPrefrence": MessageLookupByLibrary.simpleMessage("Préférences"),
    "settingsRequirements": MessageLookupByLibrary.simpleMessage(""),
    "settingsRequirementsAll": MessageLookupByLibrary.simpleMessage(""),
    "settingsRequirementsAny": MessageLookupByLibrary.simpleMessage(""),
    "settingsRequirementsDes": MessageLookupByLibrary.simpleMessage(""),
    "settingsReset": MessageLookupByLibrary.simpleMessage(""),
    "settingsRewindSec": MessageLookupByLibrary.simpleMessage("Retour rapide"),
    "settingsRewindSecDes": MessageLookupByLibrary.simpleMessage(
      "Saut arrière",
    ),
    "settingsSTAuto": MessageLookupByLibrary.simpleMessage(
      "Activation automatique de la minuterie",
    ),
    "settingsSTAutoDes": MessageLookupByLibrary.simpleMessage(
      "Démarrer la minuterie à l\'horaire programmé",
    ),
    "settingsSTDefaultTime": MessageLookupByLibrary.simpleMessage(
      "Durée par défaut",
    ),
    "settingsSTDefautTimeDes": MessageLookupByLibrary.simpleMessage(
      "Configuration de la minuterie",
    ),
    "settingsSTMode": MessageLookupByLibrary.simpleMessage(
      "Mode minuterie automatique",
    ),
    "settingsSTWaitEpisodeEnd": MessageLookupByLibrary.simpleMessage(""),
    "settingsSTWaitEpisodeEndDes": MessageLookupByLibrary.simpleMessage(""),
    "settingsSearchApi": MessageLookupByLibrary.simpleMessage(""),
    "settingsSearchEngine": MessageLookupByLibrary.simpleMessage(""),
    "settingsSearchMode": MessageLookupByLibrary.simpleMessage(""),
    "settingsSpeeds": MessageLookupByLibrary.simpleMessage("Speeds"),
    "settingsSpeedsDes": MessageLookupByLibrary.simpleMessage(
      "Customize the speeds avaliable",
    ),
    "settingsSyncing": MessageLookupByLibrary.simpleMessage("Synchronisation"),
    "settingsSyncingDes": MessageLookupByLibrary.simpleMessage(
      "Actualisation des podcasts en arrière-plan",
    ),
    "settingsSyncingInterval": MessageLookupByLibrary.simpleMessage(""),
    "settingsTapToOpenPopupMenu": MessageLookupByLibrary.simpleMessage(
      "Ouverture du menu",
    ),
    "settingsTapToOpenPopupMenuDes": MessageLookupByLibrary.simpleMessage(
      "Effectuer un appui long pour ouvrir la page de l\'épisode",
    ),
    "settingsTheme": MessageLookupByLibrary.simpleMessage("Thème"),
    "settingsTrueBlack": MessageLookupByLibrary.simpleMessage(""),
    "settingsTrueBlackDes": MessageLookupByLibrary.simpleMessage(""),
    "settingsUseSystemAccentColor": MessageLookupByLibrary.simpleMessage(""),
    "share": MessageLookupByLibrary.simpleMessage("Partager"),
    "showNotesFonts": MessageLookupByLibrary.simpleMessage("Show notes font"),
    "size": MessageLookupByLibrary.simpleMessage("Taille"),
    "skipSecondsAtEnd": MessageLookupByLibrary.simpleMessage(
      "Skip seconds at end",
    ),
    "skipSecondsAtStart": MessageLookupByLibrary.simpleMessage(
      "Passer les premières secondes du début",
    ),
    "skipSilence": MessageLookupByLibrary.simpleMessage("Skip silence"),
    "skipToNext": MessageLookupByLibrary.simpleMessage("Skip to next"),
    "skipToPrevious": MessageLookupByLibrary.simpleMessage(""),
    "sleepTimer": MessageLookupByLibrary.simpleMessage("Minuterie"),
    "sleepTimerCancel": MessageLookupByLibrary.simpleMessage(""),
    "sleepTimerExpireAt": MessageLookupByLibrary.simpleMessage(""),
    "sleepTimerStart": MessageLookupByLibrary.simpleMessage(""),
    "sleepTimerWait": MessageLookupByLibrary.simpleMessage(""),
    "sleepTimerWaitFor": MessageLookupByLibrary.simpleMessage(""),
    "sortBy": MessageLookupByLibrary.simpleMessage(""),
    "sortOrder": MessageLookupByLibrary.simpleMessage(""),
    "status": MessageLookupByLibrary.simpleMessage("Status"),
    "statusAuthError": MessageLookupByLibrary.simpleMessage(
      "Authentication error",
    ),
    "statusFail": MessageLookupByLibrary.simpleMessage("Failed"),
    "statusSuccess": MessageLookupByLibrary.simpleMessage("Successful"),
    "stop": MessageLookupByLibrary.simpleMessage("Stop"),
    "subscribe": MessageLookupByLibrary.simpleMessage("S\'abonner"),
    "subscribeExportDes": MessageLookupByLibrary.simpleMessage(
      "Exporter le fichier OPML de tous les podcasts.",
    ),
    "subscribed": MessageLookupByLibrary.simpleMessage(""),
    "suggestName": MessageLookupByLibrary.simpleMessage(""),
    "sync": MessageLookupByLibrary.simpleMessage(""),
    "syncFinished": MessageLookupByLibrary.simpleMessage(""),
    "syncNow": MessageLookupByLibrary.simpleMessage("Sync now"),
    "syncStarted": MessageLookupByLibrary.simpleMessage(""),
    "systemDefault": MessageLookupByLibrary.simpleMessage("Système par défaut"),
    "timeLastPlayed": m32,
    "timeLeft": m33,
    "to": m34,
    "toastAddPlaylist": MessageLookupByLibrary.simpleMessage(
      "Ajouter l\'épisode à la playlist.",
    ),
    "toastBackupRestoreFailure": MessageLookupByLibrary.simpleMessage(""),
    "toastBackupRestoreSuccess": MessageLookupByLibrary.simpleMessage(""),
    "toastDiscovery": MessageLookupByLibrary.simpleMessage(
      "Tutoriel réinitialisé, veuillez redémarrer l\'application.",
    ),
    "toastFileError": MessageLookupByLibrary.simpleMessage(
      "Erreur du fichier, échec de l\'abonnement.",
    ),
    "toastFileNotValid": MessageLookupByLibrary.simpleMessage(
      "Fichier invalide.",
    ),
    "toastHomeGroupNotSupport": MessageLookupByLibrary.simpleMessage(
      "Le groupe Home n\'est pas pris en charge",
    ),
    "toastImportSettingsSuccess": MessageLookupByLibrary.simpleMessage(
      "Importation des paramètres effectuée",
    ),
    "toastOneGroup": MessageLookupByLibrary.simpleMessage(
      "Sélectionnez au moins un groupe",
    ),
    "toastPodcastRecovering": MessageLookupByLibrary.simpleMessage(
      "Récupération en cours, patientez un instant.",
    ),
    "toastReadFile": MessageLookupByLibrary.simpleMessage(
      "Lecture du fichier réussie",
    ),
    "toastRecoverFailed": MessageLookupByLibrary.simpleMessage(
      "Échec de la récupération du podcast",
    ),
    "toastRemovePlaylist": MessageLookupByLibrary.simpleMessage(
      "L\'épisode a été supprimé de la playlist.",
    ),
    "toastResetSuccessful": MessageLookupByLibrary.simpleMessage(""),
    "toastRestart": MessageLookupByLibrary.simpleMessage(""),
    "toastSettingSaved": MessageLookupByLibrary.simpleMessage(
      "Paramètres sauvegardés",
    ),
    "toastTimeEqualEnd": MessageLookupByLibrary.simpleMessage("Heure de fin"),
    "toastTimeEqualStart": MessageLookupByLibrary.simpleMessage(
      "Heure de démarrage",
    ),
    "translate": MessageLookupByLibrary.simpleMessage(""),
    "translators": MessageLookupByLibrary.simpleMessage("Traducteurs"),
    "understood": MessageLookupByLibrary.simpleMessage("Compris"),
    "undo": MessageLookupByLibrary.simpleMessage("ANNULER"),
    "unlike": MessageLookupByLibrary.simpleMessage("Unlike"),
    "unliked": MessageLookupByLibrary.simpleMessage(
      "L\'épisode a été supprimé des favoris.",
    ),
    "unsupported": MessageLookupByLibrary.simpleMessage(""),
    "updateDate": MessageLookupByLibrary.simpleMessage("Date de mise à jour"),
    "updateEpisodesCount": m35,
    "updateFailed": MessageLookupByLibrary.simpleMessage(
      "Échec de la mise à jour, erreur réseau",
    ),
    "username": MessageLookupByLibrary.simpleMessage("Username"),
    "usernameRequired": MessageLookupByLibrary.simpleMessage(
      "Username required",
    ),
    "version": m36,
    "vpn": MessageLookupByLibrary.simpleMessage(""),
    "weeksCount": m37,
    "welcome": MessageLookupByLibrary.simpleMessage(""),
    "wifi": MessageLookupByLibrary.simpleMessage(""),
    "yearsCount": m38,
  };
}
