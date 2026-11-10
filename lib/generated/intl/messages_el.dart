// DO NOT EDIT. This is code generated via package:intl/generate_localized.dart
// This is a library that provides messages for a el locale. All the
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
  String get localeName => 'el';

  static String m0(groupName, count) =>
      "${Intl.plural(count, zero: '', one: '${count} επεισόδιο προστέθηκε στη λίστα ${groupName}', other: '${count} επεισόδια προστέθηκαν στη λίστα ${groupName}\n')}";

  static String m1(count) =>
      "${Intl.plural(count, zero: '', one: '${count} επεισόδιο προστέθηκε στη λίστα', other: '${count} επεισόδια προστέθηκαν στη λίστα')}";

  static String m2(count) =>
      "${Intl.plural(count, zero: 'Σήμερα', one: '${count} μέρα πριν', other: '${count} μέρες πριν')}";

  static String m3(count) =>
      "${Intl.plural(count, zero: 'Ποτέ', one: '${count} μέρα', other: '${count} μέρες')}";

  static String m4(count) =>
      "${Intl.plural(count, zero: '', one: 'Επεισόδιο', other: 'Επεισόδια')}";

  static String m5(type) => "";

  static String m6(time) => "Μέχρι ${time}";

  static String m7(icon) => "";

  static String m8(count) =>
      "${Intl.plural(count, zero: 'Ομάδα', one: 'Ομάδα', other: 'Ομάδες')}";

  static String m9(host) => "Φιλοξενούμενο στο ${host}";

  static String m10(count) =>
      "${Intl.plural(count, zero: 'Αυτή την ώρα', one: '${count} ώρα πριν', other: '${count} ώρες πριν')}";

  static String m11(count) =>
      "${Intl.plural(count, zero: '0 ώρες', one: '${count} ώρα', other: '${count} ώρες')}";

  static String m12(service) => "Ενσωμάτωση με ${service}";

  static String m13(filePath) => "";

  static String m14(userName) => "Συνδεδεμένος/η ως ${userName}";

  static String m15(count) =>
      "${Intl.plural(count, zero: 'Μόλις τώρα', one: '${count} λεπτό πριν', other: '${count} λεπτά πριν')}";

  static String m16(count) =>
      "${Intl.plural(count, zero: '0 λεπτά', one: '${count} λεπτό', other: '${count} λεπτά')}";

  static String m17(count) => "";

  static String m18(title) => "Λήψη δεδομένων ${title}";

  static String m19(title) => "Η εγγραφή επέτυχε, σφάλμα δικτύου ${title}";

  static String m20(title) => "Εγγραφή ${title}";

  static String m21(title) =>
      "Η εγγραφή επέτυχε, το podcast υπάρχει ήδη ${title}";

  static String m22(title) => "Επιτυχημένη εγγραφή ${title}";

  static String m23(title) => "Ενημέρωση ${title} ";

  static String m24(title) => "Σφάλμα ενημέρωσης ${title}";

  static String m25(count) =>
      "${Intl.plural(count, zero: '', one: 'Podcast', other: 'Podcast')}";

  static String m26(date) => "Δημοσιεύτηκε στις ${date}";

  static String m27(date) => "Αφαιρέθηκε  στις ${date}";

  static String m28(start, end) => "";

  static String m29(count) =>
      "${Intl.plural(count, zero: '0 δευτ.', one: '${count} δευτ.', other: '${count} δευτ.')}";

  static String m30(count) =>
      "${Intl.plural(count, zero: 'Μόλις τώρα', one: '${count} δευτερόλεπτο πριν', other: '${count} δευτερόλεπτα πριν')}";

  static String m31(count) => "${count} επιλεγμένα";

  static String m32(time) => "Τελευταίος χρόνος ${time}";

  static String m33(time) => "${time} Απομένει";

  static String m34(time) => "Από ${time}";

  static String m35(count) =>
      "${Intl.plural(count, zero: 'Καμία ενημέρωση', one: 'Ενημερώθηκε ${count} επεισόδιο', other: 'Ενημερώθηκαν ${count} επεισόδια')}";

  static String m36(version) => "Έκδοση: ${version}";

  static String m37(count) => "";

  static String m38(count) => "";

  final messages = _notInlinedMessages(_notInlinedMessages);
  static Map<String, Function> _notInlinedMessages(_) => <String, Function>{
    "aboutDes": MessageLookupByLibrary.simpleMessage(""),
    "add": MessageLookupByLibrary.simpleMessage("Προσθήκη"),
    "addEpisodeGroup": m0,
    "addNewEpisodeAll": m1,
    "addNewEpisodeTooltip": MessageLookupByLibrary.simpleMessage(
      "Προσθήκη νέων επεισοδίων σε λίστα",
    ),
    "addSomeGroups": MessageLookupByLibrary.simpleMessage(
      "Πρόσθεσε μερικές ομάδες",
    ),
    "after": MessageLookupByLibrary.simpleMessage(""),
    "all": MessageLookupByLibrary.simpleMessage("Όλα"),
    "apiSearch": MessageLookupByLibrary.simpleMessage(""),
    "autoDownload": MessageLookupByLibrary.simpleMessage("Αυτόματη λήψη"),
    "back": MessageLookupByLibrary.simpleMessage("Πίσω"),
    "before": MessageLookupByLibrary.simpleMessage(""),
    "between": MessageLookupByLibrary.simpleMessage(""),
    "boostVolume": MessageLookupByLibrary.simpleMessage("Ενίσχυση έντασης"),
    "buffering": MessageLookupByLibrary.simpleMessage("Φόρτωση"),
    "cancel": MessageLookupByLibrary.simpleMessage("ΑΚΥΡΩΣΗ"),
    "capitalDefault": MessageLookupByLibrary.simpleMessage(""),
    "cellularConfirm": MessageLookupByLibrary.simpleMessage(
      "Προειδοποίηση χρήσης δεδομένων",
    ),
    "cellularConfirmDes": MessageLookupByLibrary.simpleMessage(
      "Είσαι σίγουρος/η πως θες να κάνεις χρήση δεδομένων για τη λήψη;",
    ),
    "changeLayout": MessageLookupByLibrary.simpleMessage("Αλλαγή διάταξης"),
    "changelog": MessageLookupByLibrary.simpleMessage("Αλλαγές"),
    "chooseA": MessageLookupByLibrary.simpleMessage("Επέλεξε ένα"),
    "clear": MessageLookupByLibrary.simpleMessage("Εκάθαρση"),
    "clearAll": MessageLookupByLibrary.simpleMessage("Εκκαθάριση όλων"),
    "close": MessageLookupByLibrary.simpleMessage(""),
    "color": MessageLookupByLibrary.simpleMessage("Χρώμα"),
    "confirm": MessageLookupByLibrary.simpleMessage("ΕΠΙΒΕΒΑΙΩΣΗ"),
    "confirmation": MessageLookupByLibrary.simpleMessage(""),
    "contribute": MessageLookupByLibrary.simpleMessage(""),
    "createNewPlaylist": MessageLookupByLibrary.simpleMessage("Νέα λίστα"),
    "darkMode": MessageLookupByLibrary.simpleMessage("Σκοτεινό θέμα"),
    "daysAgo": m2,
    "daysCount": m3,
    "defaultQueueReminder": MessageLookupByLibrary.simpleMessage(
      "Αυτή είναι η προκαθορισμένη ουρά, δεν μπορεί να αφαιρεθεί.",
    ),
    "defaultSearchEngine": MessageLookupByLibrary.simpleMessage(
      "Προκαθορισμένη μηχανή αναζήτησης podcast",
    ),
    "defaultSearchEngineDes": MessageLookupByLibrary.simpleMessage(
      "Επέλεξε την προκαθορισμένη μηχανή αναζήτησης podcast",
    ),
    "delete": MessageLookupByLibrary.simpleMessage("Διαγραφή"),
    "deleted": MessageLookupByLibrary.simpleMessage(""),
    "deletedEpisodeDesc": MessageLookupByLibrary.simpleMessage(""),
    "deletedPodcastDesc": MessageLookupByLibrary.simpleMessage(""),
    "deselectAll": MessageLookupByLibrary.simpleMessage(""),
    "details": MessageLookupByLibrary.simpleMessage(""),
    "developer": MessageLookupByLibrary.simpleMessage("Προγραμματιστής"),
    "developerOriginal": MessageLookupByLibrary.simpleMessage(""),
    "deviceStorage": MessageLookupByLibrary.simpleMessage(""),
    "disabled": MessageLookupByLibrary.simpleMessage(""),
    "dismiss": MessageLookupByLibrary.simpleMessage("Παράβλεψη"),
    "displayVersion": MessageLookupByLibrary.simpleMessage(""),
    "done": MessageLookupByLibrary.simpleMessage("Έγινε"),
    "download": MessageLookupByLibrary.simpleMessage("Λήψεις"),
    "downloadDate": MessageLookupByLibrary.simpleMessage(""),
    "downloadRemovedToast": MessageLookupByLibrary.simpleMessage(
      "Η λήψη αφαιρέθηκε",
    ),
    "downloadStart": MessageLookupByLibrary.simpleMessage("Λήψη"),
    "downloaded": MessageLookupByLibrary.simpleMessage("Έγινε λήψη"),
    "downloading": MessageLookupByLibrary.simpleMessage(""),
    "duration": MessageLookupByLibrary.simpleMessage(""),
    "editGroupName": MessageLookupByLibrary.simpleMessage(
      "Επεξεργασία ονόματος ομάδας",
    ),
    "endOfEpisode": MessageLookupByLibrary.simpleMessage("Τέλος επεισοδίου"),
    "episode": m4,
    "fastForward": MessageLookupByLibrary.simpleMessage(
      "Γρήγορο γύρισμα μπροστά",
    ),
    "fastRewind": MessageLookupByLibrary.simpleMessage("Γρήγορο γύρισμα πίσω "),
    "featureDiscoveryEditGroup": MessageLookupByLibrary.simpleMessage(
      "Πάτα για να επεξεργαστείς την ομάδα",
    ),
    "featureDiscoveryEditGroupDes": MessageLookupByLibrary.simpleMessage(
      "Εδώ μπορείς να αλλάξεις το όνομα της ομάδας ή να τη διαγράψεις, αλλά η Αρχική ομάδα δε μπορεί να επεξεργασθεί ή να διαγραφεί",
    ),
    "featureDiscoveryEpisode": MessageLookupByLibrary.simpleMessage(
      "Προβολή επεισοδίου",
    ),
    "featureDiscoveryEpisodeDes": MessageLookupByLibrary.simpleMessage(
      "Πάτα παρατεταμένα για να παίξεις το επεισόδιο ή να το προσθέσεις σε λίστα.",
    ),
    "featureDiscoveryEpisodeTitle": MessageLookupByLibrary.simpleMessage(
      "Πάτα παρατεταμένα για να παίξεις το επεισόδιο τώρα",
    ),
    "featureDiscoveryGroup": MessageLookupByLibrary.simpleMessage(
      "Πάτα για να προσθέσεις ομάδα",
    ),
    "featureDiscoveryGroupDes": MessageLookupByLibrary.simpleMessage(
      "Η Αρχική ομάδα είναι η προεπιλεγμένη ομάδα για νέα podcast. Μπορείς να φτιάξεις νέες ομάδες και να μετακινήσεις podcast σε αυτές, καθώς και να προσθέσεις podcast σε πολλαπλές ομάδες.",
    ),
    "featureDiscoveryGroupPodcast": MessageLookupByLibrary.simpleMessage(
      "Πάτα παρατεταμένα για να ταξινομήσεις τα podcast",
    ),
    "featureDiscoveryGroupPodcastDes": MessageLookupByLibrary.simpleMessage(
      "Πάτα για να δεις περισσότερες επιλογές, ή πάτα παρατεταμένα για να ταξινομήσεις τα podcast σε όμαδα.",
    ),
    "featureDiscoveryOMPL": MessageLookupByLibrary.simpleMessage(
      "Πάτα για την εισαγωγή OPML",
    ),
    "featureDiscoveryOMPLDes": MessageLookupByLibrary.simpleMessage(
      "Εδώ μπορείς να εισάγεις αρχεία OPML, να ανοίξεις ρυθμίσεις ή να ανανεώσεις όλα τα podcast με τη μία.",
    ),
    "featureDiscoveryPlaylist": MessageLookupByLibrary.simpleMessage(
      "Πάτα για άνοιγμα λίστας",
    ),
    "featureDiscoveryPlaylistDes": MessageLookupByLibrary.simpleMessage(
      "Μπορείς να προσθέσεις επεισόδια σε λίστες από μόνος σου. Τα επεισόδια θα αφαιρούνται αυτόματα από τις λίστες αφού παιχτούν.",
    ),
    "featureDiscoveryPodcast": MessageLookupByLibrary.simpleMessage(
      "Προβολή podcast",
    ),
    "featureDiscoveryPodcastDes": MessageLookupByLibrary.simpleMessage(
      "Πάτα στο Προβολή Όλων για να προσθέσεις ομάδες ή να διαχειριστείς τα podcast.",
    ),
    "featureDiscoveryPodcastTitle": MessageLookupByLibrary.simpleMessage(
      "Σκρόλαρε κάθετα για εναλλαγή μεταξύ ομάδων",
    ),
    "featureDiscoverySearch": MessageLookupByLibrary.simpleMessage(
      "Πάτα για αναζήτηση podcast",
    ),
    "featureDiscoverySearchDes": MessageLookupByLibrary.simpleMessage(
      "Μπορείς να αναζητήσεις με το τίτλο του podcast, λέξη κλειδί, ή να κάνεις χρήση ενός συνδέσμου RSS για να εγγραφείς σε ένα νέο podacast.",
    ),
    "feedbackEmail": MessageLookupByLibrary.simpleMessage("Γράψε μου"),
    "feedbackGithub": MessageLookupByLibrary.simpleMessage("GitHub"),
    "feedbackPlay": MessageLookupByLibrary.simpleMessage(
      "Βαθμολόγηση στο PlayStore",
    ),
    "feedbackTelegram": MessageLookupByLibrary.simpleMessage(
      "Συμμετοχή στην ομάδα",
    ),
    "filter": MessageLookupByLibrary.simpleMessage("Φίλτρο"),
    "filterType": m5,
    "fontStyle": MessageLookupByLibrary.simpleMessage("Στιλ γραμματοσειράς"),
    "fonts": MessageLookupByLibrary.simpleMessage("Γραμματοσειρές"),
    "forward": MessageLookupByLibrary.simpleMessage(""),
    "from": m6,
    "getStarted": MessageLookupByLibrary.simpleMessage(""),
    "getStartedDes": m7,
    "globallyDisabled": MessageLookupByLibrary.simpleMessage(""),
    "goodNight": MessageLookupByLibrary.simpleMessage("Καληνύχτα"),
    "gpodderLoginDes": MessageLookupByLibrary.simpleMessage(
      "Συγχαρητήρια! Έχετε συνδέσει το gpodder.net λογαριασμό σας με επιτυχία. Το Tsacdop θα συγχρονίσει αυτόματα τις εγγραφές στη συσκευή σας με το gpodder.net λογαριασμό σας.",
    ),
    "groupExisted": MessageLookupByLibrary.simpleMessage("Η ομάδα υπάρχει ήδη"),
    "groupRemoveConfirm": MessageLookupByLibrary.simpleMessage(
      "Είσαι σίγουρος/η πως θες να διαγράψεις αυτή την ομάδα; Τα Podcast θα μεταφερθούν στην Αρχική ομάδα.",
    ),
    "groups": m8,
    "haptics": MessageLookupByLibrary.simpleMessage(""),
    "hapticsDes": MessageLookupByLibrary.simpleMessage(""),
    "hideListenedSetting": MessageLookupByLibrary.simpleMessage(
      "Απόκρυψη ακουσμένων",
    ),
    "hidePodcastDiscovery": MessageLookupByLibrary.simpleMessage(
      "Απόκρυψη ανακάλυψης podcast",
    ),
    "hidePodcastDiscoveryDes": MessageLookupByLibrary.simpleMessage(
      "Απόκρυψη ανακάλυψης podcast από τη σελίδα αναζήτησης",
    ),
    "homeGroupsSeeAll": MessageLookupByLibrary.simpleMessage("Προβολή όλων"),
    "homeMenuPlaylist": MessageLookupByLibrary.simpleMessage("Λίστα"),
    "homeSubMenuSortBy": MessageLookupByLibrary.simpleMessage(
      "Ταξινόμηση κατά",
    ),
    "homeTabMenuFavotite": MessageLookupByLibrary.simpleMessage("Αγαπημένα"),
    "homeTabMenuRecent": MessageLookupByLibrary.simpleMessage("Πρόσφατο"),
    "homeToprightMenuAbout": MessageLookupByLibrary.simpleMessage("Σχετικά με"),
    "homeToprightMenuImportOMPL": MessageLookupByLibrary.simpleMessage(
      "Εισαγωγή OPML",
    ),
    "homeToprightMenuRefreshAll": MessageLookupByLibrary.simpleMessage(
      "Ανανέωση όλων",
    ),
    "hostedOn": m9,
    "hoursAgo": m10,
    "hoursCount": m11,
    "import": MessageLookupByLibrary.simpleMessage("Εισαγωγή"),
    "importingOpml": MessageLookupByLibrary.simpleMessage(""),
    "interaction": MessageLookupByLibrary.simpleMessage(""),
    "intergateWith": m12,
    "introFourthPage": MessageLookupByLibrary.simpleMessage(
      "Πάτα παρατεταμένα στο επεισόδιο για γρήγορες ενέργειες.",
    ),
    "introSecondPage": MessageLookupByLibrary.simpleMessage(
      "Ανακάλυψε podcast μέσω αναζήτησης ή εισαγωγής αρχείου OPML.",
    ),
    "introThirdPage": MessageLookupByLibrary.simpleMessage(
      "Μπορείς να φτιάξεις μία ομάδα για podcast.",
    ),
    "invalidName": MessageLookupByLibrary.simpleMessage(
      "Εσφαλμένο όνομα χρήστη",
    ),
    "keepAndroidOpen": MessageLookupByLibrary.simpleMessage(""),
    "keepAndroidOpenDes": MessageLookupByLibrary.simpleMessage(""),
    "lastUpdate": MessageLookupByLibrary.simpleMessage("Τελευταία ενημέρωση"),
    "later": MessageLookupByLibrary.simpleMessage("Αργότερα"),
    "lightMode": MessageLookupByLibrary.simpleMessage("Φωτεινό θέμα"),
    "like": MessageLookupByLibrary.simpleMessage("Μου Αρέσει"),
    "likeDate": MessageLookupByLibrary.simpleMessage("Ημερομηνία αγαπημένου"),
    "liked": MessageLookupByLibrary.simpleMessage("Συνδεδεμένο"),
    "listen": MessageLookupByLibrary.simpleMessage("Άκουσε"),
    "listened": MessageLookupByLibrary.simpleMessage("Ακουσμένο"),
    "loadAllSelected": MessageLookupByLibrary.simpleMessage(""),
    "loadMore": MessageLookupByLibrary.simpleMessage("Περισσότερα"),
    "loading": MessageLookupByLibrary.simpleMessage(""),
    "localEpisodeDescription": m13,
    "localFolder": MessageLookupByLibrary.simpleMessage(""),
    "localFolderDescription": MessageLookupByLibrary.simpleMessage(""),
    "localizationWeblate": MessageLookupByLibrary.simpleMessage(""),
    "loggedInAs": m14,
    "login": MessageLookupByLibrary.simpleMessage("Σύνδεση"),
    "loginFailed": MessageLookupByLibrary.simpleMessage("Αποτυχία σύνδεσης"),
    "logout": MessageLookupByLibrary.simpleMessage("Αποσύνδεση"),
    "mark": MessageLookupByLibrary.simpleMessage("Επισήμανση"),
    "markConfirm": MessageLookupByLibrary.simpleMessage(
      "Επιβεβαίωση επισήμανσης",
    ),
    "markConfirmContent": MessageLookupByLibrary.simpleMessage(
      "Επιβεβαίωση επισήμανσης όλων των επεισοδίων ως ακουσμένα;",
    ),
    "markListened": MessageLookupByLibrary.simpleMessage(
      "Επισήμανση ως ακουσμένου",
    ),
    "markNotListened": MessageLookupByLibrary.simpleMessage(
      "Επισήμανση ως μη ακουσμένου",
    ),
    "menu": MessageLookupByLibrary.simpleMessage("Μενού"),
    "menuAllPodcasts": MessageLookupByLibrary.simpleMessage("Όλα τα podcast"),
    "menuMarkAllListened": MessageLookupByLibrary.simpleMessage(
      "Επισήμανση όλων ως ακουσμένων",
    ),
    "menuViewRSS": MessageLookupByLibrary.simpleMessage("Επίσκεψη RSS feed"),
    "menuVisitSite": MessageLookupByLibrary.simpleMessage("Επίσκεψη Ιστοτόπου"),
    "minsAgo": m15,
    "minsCount": m16,
    "mobileData": MessageLookupByLibrary.simpleMessage(""),
    "monthsCount": m17,
    "moreOptions": MessageLookupByLibrary.simpleMessage(""),
    "network": MessageLookupByLibrary.simpleMessage("Δίκτυο"),
    "networkErrorDNS": MessageLookupByLibrary.simpleMessage(""),
    "neverAutoUpdate": MessageLookupByLibrary.simpleMessage(
      "Απενεργοποίηση αυτόματων ενημερώσεων",
    ),
    "neverAutoUpdateDes": MessageLookupByLibrary.simpleMessage(""),
    "newGroup": MessageLookupByLibrary.simpleMessage("Δημιουργία νέας ομάδας"),
    "newPlain": MessageLookupByLibrary.simpleMessage(""),
    "newPlaylist": MessageLookupByLibrary.simpleMessage(""),
    "newestFirst": MessageLookupByLibrary.simpleMessage("Νεότερα πρώτα"),
    "next": MessageLookupByLibrary.simpleMessage("Επόμενο"),
    "noEpisodesFound": MessageLookupByLibrary.simpleMessage(""),
    "noPodcastGroup": MessageLookupByLibrary.simpleMessage(
      "Κανένα podcast σε αυτή την ομάδα",
    ),
    "noShownote": MessageLookupByLibrary.simpleMessage(
      "Δεν υπάρχουν διαθέσιμες σημειώσεις σόου για αυτό το επεισόδιο.",
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
    "oldestFirst": MessageLookupByLibrary.simpleMessage("Παλιότερα πρώτα"),
    "opmlFile": MessageLookupByLibrary.simpleMessage(""),
    "passwdRequired": MessageLookupByLibrary.simpleMessage(
      "Ο κωδικός πρόσβασης είναι υποχρεωτικός",
    ),
    "password": MessageLookupByLibrary.simpleMessage("Κωδικός πρόσβασης"),
    "pause": MessageLookupByLibrary.simpleMessage("Παύση"),
    "play": MessageLookupByLibrary.simpleMessage("Αναπαραγωγή"),
    "playNext": MessageLookupByLibrary.simpleMessage("Επόμενο"),
    "playNextDes": MessageLookupByLibrary.simpleMessage(
      "Προσθήκη επεισοδίου στη κορυφή της λίστας",
    ),
    "playback": MessageLookupByLibrary.simpleMessage("Έλεγχος αναπαραγωγής "),
    "player": MessageLookupByLibrary.simpleMessage("Προβολή αναπαραγωγής"),
    "playerHeightMed": MessageLookupByLibrary.simpleMessage("Μέτριο"),
    "playerHeightShort": MessageLookupByLibrary.simpleMessage("Χαμηλό"),
    "playerHeightTall": MessageLookupByLibrary.simpleMessage("Ψηλό"),
    "playing": MessageLookupByLibrary.simpleMessage("Αναπαραγωγή σε εξέλιξη "),
    "playlistExists": MessageLookupByLibrary.simpleMessage(""),
    "playlistNameEmpty": MessageLookupByLibrary.simpleMessage(
      "Το όνομα λίστας είναι κενό",
    ),
    "playlists": MessageLookupByLibrary.simpleMessage("Λίστες"),
    "plugins": MessageLookupByLibrary.simpleMessage("Πρόσθετα"),
    "podcast": m25,
    "podcastList": MessageLookupByLibrary.simpleMessage(""),
    "podcastSubscribed": MessageLookupByLibrary.simpleMessage(
      "Podcast εγγράφη",
    ),
    "popupMenuDownloadDes": MessageLookupByLibrary.simpleMessage(
      "Λήψη επεισοδίου ",
    ),
    "popupMenuLaterDes": MessageLookupByLibrary.simpleMessage(
      "Προσθήκη επεισοδίου σε λίστα",
    ),
    "popupMenuLikeDes": MessageLookupByLibrary.simpleMessage(
      "Προσθήκη επεισοδίου στα αγαπημένα",
    ),
    "popupMenuMarkDes": MessageLookupByLibrary.simpleMessage(
      "Επισήμανση επεισοδίου ως ακουσμένο",
    ),
    "popupMenuPlayDes": MessageLookupByLibrary.simpleMessage(
      "Αναπαραγωγή επεισοδίου",
    ),
    "privacyPolicy": MessageLookupByLibrary.simpleMessage(
      "Πολιτική Απορρήτου ",
    ),
    "publishDate": MessageLookupByLibrary.simpleMessage(""),
    "published": m26,
    "publishedDaily": MessageLookupByLibrary.simpleMessage(
      "Δημοσίευεται καθημερινά",
    ),
    "publishedMonthly": MessageLookupByLibrary.simpleMessage(
      "Δημοσίευεται μηνιαία",
    ),
    "publishedWeekly": MessageLookupByLibrary.simpleMessage(
      "Δημοσίευεται εβδομαδιαια",
    ),
    "publishedYearly": MessageLookupByLibrary.simpleMessage(
      "Δημοσίευεται ετήσια",
    ),
    "queue": MessageLookupByLibrary.simpleMessage("Ουρά"),
    "random": MessageLookupByLibrary.simpleMessage(""),
    "recoverSubscribe": MessageLookupByLibrary.simpleMessage(
      "Ανάκτηση συνδρομής",
    ),
    "refresh": MessageLookupByLibrary.simpleMessage("Ανανέωση"),
    "refreshArtwork": MessageLookupByLibrary.simpleMessage(
      "Ενημέρωση γραφικών",
    ),
    "remove": MessageLookupByLibrary.simpleMessage("Αφαίρεση"),
    "removeConfirm": MessageLookupByLibrary.simpleMessage(
      "Επιβεβαίωση κατάργησης",
    ),
    "removeDownload": MessageLookupByLibrary.simpleMessage(""),
    "removeNewMark": MessageLookupByLibrary.simpleMessage(
      "Αφαίρεση επισήμανσης νέου",
    ),
    "removePodcastDes": MessageLookupByLibrary.simpleMessage(
      "Είσαι σίγουρος/η πως θες να καταργήσεις την εγγραφή σου; ",
    ),
    "removedAt": m27,
    "restartAppForEffect": MessageLookupByLibrary.simpleMessage(""),
    "satellite": MessageLookupByLibrary.simpleMessage(""),
    "save": MessageLookupByLibrary.simpleMessage("Αποθήκευση"),
    "schedule": MessageLookupByLibrary.simpleMessage("Πρόγραμμα"),
    "scheduleDisabled": MessageLookupByLibrary.simpleMessage(""),
    "scheduleTime": m28,
    "search": MessageLookupByLibrary.simpleMessage("Αναζήτηση"),
    "searchApi": MessageLookupByLibrary.simpleMessage(""),
    "searchEngine": MessageLookupByLibrary.simpleMessage(""),
    "searchEpisode": MessageLookupByLibrary.simpleMessage(
      "Αναζήτηση επεισοδίου",
    ),
    "searchHelper": MessageLookupByLibrary.simpleMessage(
      "Πληκτρολόγησε το όνομα του podcast, λέξεις κλειδιά ή το URL ενός feed.",
    ),
    "searchInstructions": MessageLookupByLibrary.simpleMessage(""),
    "searchInvalidRss": MessageLookupByLibrary.simpleMessage(
      "Εσφαλμένος σύνδεσμος RSS",
    ),
    "searchPodcast": MessageLookupByLibrary.simpleMessage("Αναζήτηση podcast"),
    "searchWeb": MessageLookupByLibrary.simpleMessage(""),
    "secCount": m29,
    "secondsAgo": m30,
    "selectMode": MessageLookupByLibrary.simpleMessage(""),
    "selected": m31,
    "settingStorage": MessageLookupByLibrary.simpleMessage("Χώρος αποθήκευσης"),
    "settings": MessageLookupByLibrary.simpleMessage("Ρυθμίσεις"),
    "settingsAccentColor": MessageLookupByLibrary.simpleMessage(
      "Χρώμα έμφασης",
    ),
    "settingsAppIntro": MessageLookupByLibrary.simpleMessage(
      "Εισαγωγή εφαρμογής",
    ),
    "settingsAppearance": MessageLookupByLibrary.simpleMessage("Εμφάνιση"),
    "settingsAppearanceDes": MessageLookupByLibrary.simpleMessage(
      "Χρώματα και θέματα",
    ),
    "settingsAudioCache": MessageLookupByLibrary.simpleMessage(
      "Προσωρινή μνήμη ήχου",
    ),
    "settingsAudioCacheDes": MessageLookupByLibrary.simpleMessage(
      "Μέγιστο μέγεθος προσωρινής μνήμης ήχου",
    ),
    "settingsAutoDelete": MessageLookupByLibrary.simpleMessage(
      "Αυτόματη διαγραφή λήψεων μετά από",
    ),
    "settingsAutoDeleteAfterPlayed": MessageLookupByLibrary.simpleMessage(""),
    "settingsAutoDeleteAfterTime": MessageLookupByLibrary.simpleMessage(""),
    "settingsAutoDeleteAfterTimeDes": MessageLookupByLibrary.simpleMessage(""),
    "settingsAutoDeleteDes": MessageLookupByLibrary.simpleMessage(
      "Προεπιλογή 30 ημέρες",
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
      "Αυτόματη αναπαραγωγή επόμενου επεισοδίου στη λίστα",
    ),
    "settingsAutoSync": MessageLookupByLibrary.simpleMessage(""),
    "settingsAutoSyncDes": MessageLookupByLibrary.simpleMessage(""),
    "settingsBackup": MessageLookupByLibrary.simpleMessage(
      "Αντίγραφο ασφαλείας",
    ),
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
      "Αντίγραφο ασφαλείας δεδομένων εφαρμογής",
    ),
    "settingsBackupFile": MessageLookupByLibrary.simpleMessage(""),
    "settingsBackupLegacyFile": MessageLookupByLibrary.simpleMessage(""),
    "settingsBackupLegacyFileDes": MessageLookupByLibrary.simpleMessage(""),
    "settingsBackupPassword": MessageLookupByLibrary.simpleMessage(""),
    "settingsBackupPasswordDes": MessageLookupByLibrary.simpleMessage(""),
    "settingsBoostVolume": MessageLookupByLibrary.simpleMessage(
      "Επιπέδο ενίσχυσης έντασης",
    ),
    "settingsBoostVolumeDes": MessageLookupByLibrary.simpleMessage(
      "Αλλαγή επιπέδου ενίσχυσης έντασης",
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
      "Προεπιλεγμένη προβολή πλέγματος",
    ),
    "settingsDefaultGridDownload": MessageLookupByLibrary.simpleMessage(
      "Καρτέλα λήψεων",
    ),
    "settingsDefaultGridFavorite": MessageLookupByLibrary.simpleMessage(
      "Καρτέλα αγαπημένων",
    ),
    "settingsDefaultGridPodcast": MessageLookupByLibrary.simpleMessage(
      "Σελίδα podcast",
    ),
    "settingsDefaultGridRecent": MessageLookupByLibrary.simpleMessage(
      "Καρτέλα πρόσφατων",
    ),
    "settingsDiscovery": MessageLookupByLibrary.simpleMessage(
      "Ενεργοποίηση λειτουργιών ανακάλυψης",
    ),
    "settingsDiscoveryDes": MessageLookupByLibrary.simpleMessage(""),
    "settingsDownloadAskOnForbidden": MessageLookupByLibrary.simpleMessage(""),
    "settingsDownloadAskOnForbiddenDes": MessageLookupByLibrary.simpleMessage(
      "",
    ),
    "settingsDownloadPosition": MessageLookupByLibrary.simpleMessage(
      "Λήψη θέσης",
    ),
    "settingsDownloads": MessageLookupByLibrary.simpleMessage(""),
    "settingsDownloadsDes": MessageLookupByLibrary.simpleMessage(""),
    "settingsEpisodeManagement": MessageLookupByLibrary.simpleMessage(""),
    "settingsExportDes": MessageLookupByLibrary.simpleMessage(
      "Ρυθμίσεις εξαγωγής και εισαγωγής",
    ),
    "settingsFastForwardSec": MessageLookupByLibrary.simpleMessage(
      "Δευτερολέπτα γυρίσματος μπροστά",
    ),
    "settingsFastForwardSecDes": MessageLookupByLibrary.simpleMessage(
      "Αλλαγή δευτερολέπτων γυρίσματος μπροστά στη προβολή αναπαραγωγής",
    ),
    "settingsFeedback": MessageLookupByLibrary.simpleMessage("Feedback"),
    "settingsFeedbackDes": MessageLookupByLibrary.simpleMessage(
      "Επαναφορά λειτουργίας εκμάθησης",
    ),
    "settingsForbiddenDownloadConnections":
        MessageLookupByLibrary.simpleMessage(""),
    "settingsForbiddenDownloadConnectionsDes":
        MessageLookupByLibrary.simpleMessage(""),
    "settingsFullStop": MessageLookupByLibrary.simpleMessage(""),
    "settingsFullStopDes": MessageLookupByLibrary.simpleMessage(""),
    "settingsGeneral": MessageLookupByLibrary.simpleMessage(""),
    "settingsHistory": MessageLookupByLibrary.simpleMessage("Ιστορικό"),
    "settingsHistoryDes": MessageLookupByLibrary.simpleMessage(
      "Εξαγωγή και εισαγωγή ρυθμίσεων",
    ),
    "settingsHomeTabAdd": MessageLookupByLibrary.simpleMessage(""),
    "settingsHomeTabName": MessageLookupByLibrary.simpleMessage(""),
    "settingsHomeTabNew": MessageLookupByLibrary.simpleMessage(""),
    "settingsHomeTabs": MessageLookupByLibrary.simpleMessage(""),
    "settingsInfo": MessageLookupByLibrary.simpleMessage("Πληροφορίες"),
    "settingsInterface": MessageLookupByLibrary.simpleMessage("Διεπαφή"),
    "settingsInterfaceDes": MessageLookupByLibrary.simpleMessage(""),
    "settingsLanguage": MessageLookupByLibrary.simpleMessage(""),
    "settingsLegacy": MessageLookupByLibrary.simpleMessage(""),
    "settingsLibraries": MessageLookupByLibrary.simpleMessage("Βιβλιοθήκες"),
    "settingsLibrariesDes": MessageLookupByLibrary.simpleMessage(
      "Βιβλιοθήκες ανοιχτού κώδικα που χρησιμοποιούνται από την εφαρμογή",
    ),
    "settingsLookAndFeel": MessageLookupByLibrary.simpleMessage(""),
    "settingsLookAndFeelDes": MessageLookupByLibrary.simpleMessage(""),
    "settingsManageDownload": MessageLookupByLibrary.simpleMessage(
      "Διαχείριση λήψεων",
    ),
    "settingsManageDownloadDes": MessageLookupByLibrary.simpleMessage(
      "Διαχείριση ληφθέντων αρχείων ήχου",
    ),
    "settingsManufacturerNotificationLayout":
        MessageLookupByLibrary.simpleMessage(""),
    "settingsMarkListenedSkip": MessageLookupByLibrary.simpleMessage(
      "Επισήμανση ως ακουσμένου όταν παραλείπεται",
    ),
    "settingsMarkListenedSkipDes": MessageLookupByLibrary.simpleMessage(
      "Αυτόματη επισήμανση του επεισοδίου ως ακουσμένου κατά τη παράλειψή του",
    ),
    "settingsMediaControls": MessageLookupByLibrary.simpleMessage(""),
    "settingsMediaControlsDes": MessageLookupByLibrary.simpleMessage(""),
    "settingsMenuAutoPlay": MessageLookupByLibrary.simpleMessage(
      "Αυτόματη αναπαραγωγή επομένου",
    ),
    "settingsNetworkCellular": MessageLookupByLibrary.simpleMessage(
      "Ερώτηση πριν τη χρήση δεδομένων",
    ),
    "settingsNetworkCellularDes": MessageLookupByLibrary.simpleMessage(
      "Ερώτηση για επιβεβαίωση λήψης επεισοδίων κατά τη χρήση δεδομένων",
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
      "Αναδυόμενο μενού επεισοδίων",
    ),
    "settingsPopupMenuDes": MessageLookupByLibrary.simpleMessage(
      "Αλλαγή αναδυόμενου μενού επεισοδίων",
    ),
    "settingsPrefrence": MessageLookupByLibrary.simpleMessage("Προτίμηση"),
    "settingsRequirements": MessageLookupByLibrary.simpleMessage(""),
    "settingsRequirementsAll": MessageLookupByLibrary.simpleMessage(""),
    "settingsRequirementsAny": MessageLookupByLibrary.simpleMessage(""),
    "settingsRequirementsDes": MessageLookupByLibrary.simpleMessage(""),
    "settingsReset": MessageLookupByLibrary.simpleMessage(""),
    "settingsRewindSec": MessageLookupByLibrary.simpleMessage(
      "Δευτερολέπτα γυρίσματος πίσω",
    ),
    "settingsRewindSecDes": MessageLookupByLibrary.simpleMessage(
      "Αλλαγή δευτερολέπτων γυρίσματος πίσω στη προβολή αναπαραγωγής",
    ),
    "settingsSTAuto": MessageLookupByLibrary.simpleMessage(
      "Αυτόματη ενεργοποίηση χρονοδιακόπτη",
    ),
    "settingsSTAutoDes": MessageLookupByLibrary.simpleMessage(
      "Αυτόματη έναρξη χρονοδιακόπτη την προγραμματισμένη ώρα",
    ),
    "settingsSTDefaultTime": MessageLookupByLibrary.simpleMessage(
      "Προεπιλεγμένος χρόνος",
    ),
    "settingsSTDefautTimeDes": MessageLookupByLibrary.simpleMessage(
      "Προεπιλεγμένος χρόνος χρονοδιακόπτη",
    ),
    "settingsSTMode": MessageLookupByLibrary.simpleMessage(
      "Λειτουργία αυτόματου χρονοδιακόπτη",
    ),
    "settingsSTWaitEpisodeEnd": MessageLookupByLibrary.simpleMessage(""),
    "settingsSTWaitEpisodeEndDes": MessageLookupByLibrary.simpleMessage(""),
    "settingsSearchApi": MessageLookupByLibrary.simpleMessage(""),
    "settingsSearchEngine": MessageLookupByLibrary.simpleMessage(""),
    "settingsSearchMode": MessageLookupByLibrary.simpleMessage(""),
    "settingsSpeeds": MessageLookupByLibrary.simpleMessage("Ταχύτητες"),
    "settingsSpeedsDes": MessageLookupByLibrary.simpleMessage(
      "Επεξεργασία διαθέσιμων ταχυτήτων",
    ),
    "settingsSyncing": MessageLookupByLibrary.simpleMessage("Συγχρονισμός"),
    "settingsSyncingDes": MessageLookupByLibrary.simpleMessage(
      "Ανανέωση podcast στο παρασκήνιο",
    ),
    "settingsSyncingInterval": MessageLookupByLibrary.simpleMessage(""),
    "settingsTapToOpenPopupMenu": MessageLookupByLibrary.simpleMessage(
      "Πάτησε για να ανοίξεις το αναδυόμενο μενού",
    ),
    "settingsTapToOpenPopupMenuDes": MessageLookupByLibrary.simpleMessage(
      "Πρέπει να πατήσεις παρατεταμένα για το άνοιγμα της σελίδας επεισοδίου",
    ),
    "settingsTheme": MessageLookupByLibrary.simpleMessage("Θέμα"),
    "settingsTrueBlack": MessageLookupByLibrary.simpleMessage(""),
    "settingsTrueBlackDes": MessageLookupByLibrary.simpleMessage(""),
    "settingsUseSystemAccentColor": MessageLookupByLibrary.simpleMessage(""),
    "share": MessageLookupByLibrary.simpleMessage("Κοινοποίηση"),
    "showNotesFonts": MessageLookupByLibrary.simpleMessage(
      "Προβολή γραμματοσειράς σημειώσεων",
    ),
    "size": MessageLookupByLibrary.simpleMessage("Μέγεθος"),
    "skipSecondsAtEnd": MessageLookupByLibrary.simpleMessage(
      "Παράλειψη δευτερολέπτων στο τέλος",
    ),
    "skipSecondsAtStart": MessageLookupByLibrary.simpleMessage(
      "Παράληψη αρχικών δευτερολέπτων",
    ),
    "skipSilence": MessageLookupByLibrary.simpleMessage("Παράλειψη σιγής"),
    "skipToNext": MessageLookupByLibrary.simpleMessage("Παράλειψη"),
    "skipToPrevious": MessageLookupByLibrary.simpleMessage(""),
    "sleepTimer": MessageLookupByLibrary.simpleMessage("Χρονοδιακόπτης"),
    "sleepTimerCancel": MessageLookupByLibrary.simpleMessage(""),
    "sleepTimerExpireAt": MessageLookupByLibrary.simpleMessage(""),
    "sleepTimerStart": MessageLookupByLibrary.simpleMessage(""),
    "sleepTimerWait": MessageLookupByLibrary.simpleMessage(""),
    "sleepTimerWaitFor": MessageLookupByLibrary.simpleMessage(""),
    "sortBy": MessageLookupByLibrary.simpleMessage(""),
    "sortOrder": MessageLookupByLibrary.simpleMessage(""),
    "status": MessageLookupByLibrary.simpleMessage("Κατάσταση"),
    "statusAuthError": MessageLookupByLibrary.simpleMessage(
      "Σφάλμα πιστοποίησης",
    ),
    "statusFail": MessageLookupByLibrary.simpleMessage("Αποτυχία"),
    "statusSuccess": MessageLookupByLibrary.simpleMessage("Επιτυχία"),
    "stop": MessageLookupByLibrary.simpleMessage("Σταμάτημα"),
    "subscribe": MessageLookupByLibrary.simpleMessage("Εγγραφή"),
    "subscribeExportDes": MessageLookupByLibrary.simpleMessage(
      "Εξαγωγή αρχείου OPML όλων των podcast",
    ),
    "subscribed": MessageLookupByLibrary.simpleMessage(""),
    "suggestName": MessageLookupByLibrary.simpleMessage(""),
    "sync": MessageLookupByLibrary.simpleMessage(""),
    "syncFinished": MessageLookupByLibrary.simpleMessage(""),
    "syncNow": MessageLookupByLibrary.simpleMessage("Συγχρονισμός τώρα"),
    "syncStarted": MessageLookupByLibrary.simpleMessage(""),
    "systemDefault": MessageLookupByLibrary.simpleMessage(
      "Προεπιλογή συστήματος",
    ),
    "timeLastPlayed": m32,
    "timeLeft": m33,
    "to": m34,
    "toastAddPlaylist": MessageLookupByLibrary.simpleMessage(
      "Προστέθηκε στη λίστα",
    ),
    "toastBackupRestoreFailure": MessageLookupByLibrary.simpleMessage(""),
    "toastBackupRestoreSuccess": MessageLookupByLibrary.simpleMessage(""),
    "toastDiscovery": MessageLookupByLibrary.simpleMessage(
      "Λειτουργία ανακάλυψης ενεργή, παρακαλώ ξανανοίξτε την εφαρμογή",
    ),
    "toastFileError": MessageLookupByLibrary.simpleMessage(
      "Σφάλμα αρχείου, η εγγραφή απέτυχε ",
    ),
    "toastFileNotValid": MessageLookupByLibrary.simpleMessage(
      "Μη έγκυρο αρχείο",
    ),
    "toastHomeGroupNotSupport": MessageLookupByLibrary.simpleMessage(
      "Η Αρχική ομάδα δεν υποστηρίζεται",
    ),
    "toastImportSettingsSuccess": MessageLookupByLibrary.simpleMessage(
      "Εισαγωγή ρυθμίσεων επιτυχής",
    ),
    "toastOneGroup": MessageLookupByLibrary.simpleMessage(
      "Επέλεξε τουλάχιστον μία ομάδα",
    ),
    "toastPodcastRecovering": MessageLookupByLibrary.simpleMessage(
      "Ανάκτηση, περίμενε λίγο",
    ),
    "toastReadFile": MessageLookupByLibrary.simpleMessage(
      "Διάβασμα αρχείου επιτυχές",
    ),
    "toastRecoverFailed": MessageLookupByLibrary.simpleMessage(
      "Η ανάκτηση του podcast απέτυχε",
    ),
    "toastRemovePlaylist": MessageLookupByLibrary.simpleMessage(
      "Τα επεισόδιο αφαιρέθηκε από τη λίστα",
    ),
    "toastResetSuccessful": MessageLookupByLibrary.simpleMessage(""),
    "toastRestart": MessageLookupByLibrary.simpleMessage(""),
    "toastSettingSaved": MessageLookupByLibrary.simpleMessage(
      "Οι ρυθμίσεις αποθηκεύτηκαν ",
    ),
    "toastTimeEqualEnd": MessageLookupByLibrary.simpleMessage(
      "Ο επιλεγμένος χρόνος είναι ίδιος με τον χρόνο λήξης",
    ),
    "toastTimeEqualStart": MessageLookupByLibrary.simpleMessage(
      "Ο επιλεγμένος χρόνος είναι ίδιος με τον χρόνο έναρξης",
    ),
    "translate": MessageLookupByLibrary.simpleMessage(""),
    "translators": MessageLookupByLibrary.simpleMessage("Μεταφραστές"),
    "understood": MessageLookupByLibrary.simpleMessage("Κατάλαβα"),
    "undo": MessageLookupByLibrary.simpleMessage("ΑΝΑΙΡΕΣΗ"),
    "unlike": MessageLookupByLibrary.simpleMessage("Δεν Μου Αρέσει"),
    "unliked": MessageLookupByLibrary.simpleMessage(
      "Τα επεισόδιο αφαιρέθηκε από τα αγαπημένα",
    ),
    "unsupported": MessageLookupByLibrary.simpleMessage(""),
    "updateDate": MessageLookupByLibrary.simpleMessage("Ημερομηνία ενημέρωσης"),
    "updateEpisodesCount": m35,
    "updateFailed": MessageLookupByLibrary.simpleMessage(
      "Ενημέρωση ανεπιτυχείς, σφάλμα δικτύου",
    ),
    "username": MessageLookupByLibrary.simpleMessage("Όνομα χρήστη"),
    "usernameRequired": MessageLookupByLibrary.simpleMessage(
      "Το όνομα χρήστη είναι υποχρεωτικό",
    ),
    "version": m36,
    "vpn": MessageLookupByLibrary.simpleMessage(""),
    "weeksCount": m37,
    "welcome": MessageLookupByLibrary.simpleMessage(""),
    "wifi": MessageLookupByLibrary.simpleMessage(""),
    "yearsCount": m38,
  };
}
