// DO NOT EDIT. This is code generated via package:intl/generate_localized.dart
// This is a library that provides messages for a tr locale. All the
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
  String get localeName => 'tr';

  static String m2(groupName, count) =>
      "${Intl.plural(count, zero: '', one: '${groupName} deki ${count} bölüm çalma listesine eklendi', other: '${groupName} deki ${count} bölüm çalma listesine eklendi')}";

  static String m3(count) =>
      "${Intl.plural(count, zero: '', one: '${count} bölüm çalma listesine eklendi', other: '${count} bölüm çalma listesine eklendi')}";

  static String m4(count) =>
      "${Intl.plural(count, zero: 'Bugün', one: '${count} gün önce', other: '${count} gün önce')}";

  static String m5(count) =>
      "${Intl.plural(count, zero: '${count} gün', one: '${count} gün', other: '${count} gün')}";

  static String m6(count) =>
      "${Intl.plural(count, zero: '', one: 'Bölüm', other: 'Bölümler')}";

  static String m32(type) => "${type} Filtresi";

  static String m7(time) => "${time} \'dan";

  static String m33(icon) => "Podcast aramak için ${icon}\'a dokun";

  static String m8(count) =>
      "${Intl.plural(count, zero: 'Grup', one: 'Grup', other: 'Gruplar')}";

  static String m0(host) => "${host} da depolanır";

  static String m9(count) =>
      "${Intl.plural(count, zero: 'Geçen saat', one: '${count} saat önce', other: '${count} saat önce')}";

  static String m10(count) =>
      "${Intl.plural(count, zero: '0 saat', one: '${count} saat', other: '${count} saat')}";

  static String m11(service) => "${service} ile bağlantı kur";

  static String m34(filePath) => "${filePath} adresindeki yerel bölüm";

  static String m1(userName) => "${userName} olarak giriş yapıldı";

  static String m12(count) =>
      "${Intl.plural(count, zero: 'Şimdi', one: '${count} dakika önce', other: '${count} dakika önce')}";

  static String m13(count) =>
      "${Intl.plural(count, zero: '0 dk', one: '${count} dk', other: '${count} dk')}";

  static String m35(count) =>
      "${Intl.plural(count, zero: '${count} ay', one: '${count} ay', other: '${count} ay')}";

  static String m14(title) => "Bilgiler toplanıyor ${title}";

  static String m15(title) =>
      "Abonelik başarısız oldu, bağlantı hatası ${title}";

  static String m16(title) => "Abone ol ${title}";

  static String m17(title) =>
      "Abonelik başarısız oldu, podcast zaten mevcut ${title}";

  static String m18(title) => "${title}\'a başarıyla abone olundu";

  static String m19(title) => "Güncelleme ${title}";

  static String m20(title) => "Güncelleme hatası ${title}";

  static String m21(count) =>
      "${Intl.plural(count, zero: '', one: 'Podcast', other: 'Podcast\'ler')}";

  static String m22(date) => "${date} tarihinde yayınlandı";

  static String m23(date) => "${date} tarihinde kaldırıldı";

  static String m36(start, end) => "Program: ${start} - ${end}";

  static String m24(count) =>
      "${Intl.plural(count, zero: '0 sn', one: '${count} sn', other: '${count} sn')}";

  static String m25(count) =>
      "${Intl.plural(count, zero: 'Şimdi', one: '${count} saniye önce', other: '${count} saniye önce')}";

  static String m26(count) => "${count} seçilen";

  static String m27(time) => "En son ${time}";

  static String m28(time) => "${time} Kaldı";

  static String m29(time) => "${time} \'a";

  static String m30(count) =>
      "${Intl.plural(count, zero: 'Güncelleme yok', one: '${count} bölüm güncellendi', other: '${count} bölüm güncellendi')}";

  static String m31(version) => "Version: ${version}";

  static String m37(count) =>
      "${Intl.plural(count, zero: '${count} hafta', one: '${count} hafta', other: '${count} hafta')}";

  static String m38(count) =>
      "${Intl.plural(count, zero: '${count} yıl', one: '${count} yıl', other: '${count} yıl')}";

  final messages = _notInlinedMessages(_notInlinedMessages);
  static Map<String, Function> _notInlinedMessages(_) => <String, Function>{
        "aboutDes": MessageLookupByLibrary.simpleMessage(
            "Tsacdop, Flutter ile inşa edilmiş zarif ve özelleştirilebilir bir podcast oynatıcıdır."),
        "add": MessageLookupByLibrary.simpleMessage("Ekle"),
        "addEpisodeGroup": m2,
        "addNewEpisodeAll": m3,
        "addNewEpisodeTooltip": MessageLookupByLibrary.simpleMessage(
            "Çalma listesine yeni bölüm ekle"),
        "addSomeGroups": MessageLookupByLibrary.simpleMessage("Grup ekle"),
        "after": MessageLookupByLibrary.simpleMessage("Sonrası"),
        "all": MessageLookupByLibrary.simpleMessage("Hepsi"),
        "apiSearch": MessageLookupByLibrary.simpleMessage("Api Araması"),
        "autoDownload":
            MessageLookupByLibrary.simpleMessage("Otomatik indirme"),
        "back": MessageLookupByLibrary.simpleMessage("Geri"),
        "before": MessageLookupByLibrary.simpleMessage("Öncesi"),
        "between": MessageLookupByLibrary.simpleMessage("Arası"),
        "boostVolume": MessageLookupByLibrary.simpleMessage("Sesi yükselt"),
        "buffering":
            MessageLookupByLibrary.simpleMessage("Arabelleğe alınıyor"),
        "cancel": MessageLookupByLibrary.simpleMessage("İPTAL"),
        "capitalDefault": MessageLookupByLibrary.simpleMessage("Varsayılan"),
        "cellularConfirm":
            MessageLookupByLibrary.simpleMessage("Hücresel veri uyarısı"),
        "cellularConfirmDes": MessageLookupByLibrary.simpleMessage(
            "İndirmek için hücresel veri kullanmak istediğinden emin misin?"),
        "changeLayout":
            MessageLookupByLibrary.simpleMessage("Görünümü değiştir"),
        "changelog": MessageLookupByLibrary.simpleMessage("Değişenler"),
        "chooseA": MessageLookupByLibrary.simpleMessage("Seç"),
        "clear": MessageLookupByLibrary.simpleMessage("Temizle"),
        "clearAll": MessageLookupByLibrary.simpleMessage("Hepsini sil"),
        "close": MessageLookupByLibrary.simpleMessage("Kapat"),
        "color": MessageLookupByLibrary.simpleMessage("renk"),
        "confirm": MessageLookupByLibrary.simpleMessage("ONAY"),
        "confirmation": MessageLookupByLibrary.simpleMessage("Onay"),
        "contribute": MessageLookupByLibrary.simpleMessage("Katkıda bulun"),
        "createNewPlaylist":
            MessageLookupByLibrary.simpleMessage("Yeni çalma listesi"),
        "darkMode": MessageLookupByLibrary.simpleMessage("Karanlık mod"),
        "daysAgo": m4,
        "daysCount": m5,
        "defaultQueueReminder": MessageLookupByLibrary.simpleMessage(
            "Varsayılan sıralama kaldırılamaz."),
        "defaultSearchEngine": MessageLookupByLibrary.simpleMessage(
            "Varsayılan podcast arama motoru"),
        "defaultSearchEngineDes": MessageLookupByLibrary.simpleMessage(
            "Varsayılan podcast arama motorunu seçin"),
        "delete": MessageLookupByLibrary.simpleMessage("Sil"),
        "deleted": MessageLookupByLibrary.simpleMessage("Silindi"),
        "deletedEpisodeDesc": MessageLookupByLibrary.simpleMessage(
            "Bu bölüm veritabanından silindi"),
        "deletedPodcastDesc": MessageLookupByLibrary.simpleMessage(
            "Bu podcast veritabanından silinmiştir"),
        "deselectAll":
            MessageLookupByLibrary.simpleMessage("Tüm Seçimi Kaldır"),
        "details": MessageLookupByLibrary.simpleMessage("Detaylar"),
        "developer": MessageLookupByLibrary.simpleMessage("Geliştirici"),
        "developerOriginal":
            MessageLookupByLibrary.simpleMessage("Orijinal geliştirici"),
        "deviceStorage": MessageLookupByLibrary.simpleMessage("Cihaz Hafızası"),
        "disabled": MessageLookupByLibrary.simpleMessage("Devre dışı"),
        "dismiss": MessageLookupByLibrary.simpleMessage("Kaybol"),
        "displayVersion":
            MessageLookupByLibrary.simpleMessage("Gösterilen Sürüm"),
        "done": MessageLookupByLibrary.simpleMessage("Bitti"),
        "download": MessageLookupByLibrary.simpleMessage("İndirilen"),
        "downloadDate": MessageLookupByLibrary.simpleMessage("İndirme Tarihi"),
        "downloadRemovedToast":
            MessageLookupByLibrary.simpleMessage("İndirme kaldırıldı"),
        "downloadStart": MessageLookupByLibrary.simpleMessage("İndiriliyor"),
        "downloaded": MessageLookupByLibrary.simpleMessage("İndirilenler"),
        "downloading": MessageLookupByLibrary.simpleMessage("İndiriliyor"),
        "duration": MessageLookupByLibrary.simpleMessage("Süre"),
        "editGroupName":
            MessageLookupByLibrary.simpleMessage("Grubun adını değiştir"),
        "endOfEpisode":
            MessageLookupByLibrary.simpleMessage("Sonuna kadar oynat"),
        "episode": m6,
        "fastForward": MessageLookupByLibrary.simpleMessage("İleri sar"),
        "fastRewind": MessageLookupByLibrary.simpleMessage("Geri sar"),
        "featureDiscoveryEditGroup":
            MessageLookupByLibrary.simpleMessage("Grubu düzenlemek için tıkla"),
        "featureDiscoveryEditGroupDes": MessageLookupByLibrary.simpleMessage(
            "Buradan grup ismini değiştirebilir ya da silebilirsin, ancak \'Home\' grubu değiştirilemez"),
        "featureDiscoveryEpisode":
            MessageLookupByLibrary.simpleMessage("Bölüm görünümü"),
        "featureDiscoveryEpisodeDes": MessageLookupByLibrary.simpleMessage(
            "Bölümü oynatmak veya çalma listesine eklemek için uzun dokun."),
        "featureDiscoveryEpisodeTitle": MessageLookupByLibrary.simpleMessage(
            "Bölümü hemen oynatmak için uzun bas"),
        "featureDiscoveryGroup":
            MessageLookupByLibrary.simpleMessage("Grup eklemek için dokun"),
        "featureDiscoveryGroupDes": MessageLookupByLibrary.simpleMessage(
            "Yeni podcastler varsayılan olarak \"Home\" grubuna eklenir. Yeni gruplar oluşturabilir, podcastleri başka gruplara taşıyabilir veya birden fazla gruba ekleyebilirsin."),
        "featureDiscoveryGroupPodcast": MessageLookupByLibrary.simpleMessage(
            "Podcastleri sıralamak için uzun bas"),
        "featureDiscoveryGroupPodcastDes": MessageLookupByLibrary.simpleMessage(
            "Daha fazla seçenek için tıklayabilirsin ya da uzunca basarak grupdaki podcastleri sıralayabilirsin."),
        "featureDiscoveryOMPL": MessageLookupByLibrary.simpleMessage(
            "OPML dosyasını içe aktarmak için dokun"),
        "featureDiscoveryOMPLDes": MessageLookupByLibrary.simpleMessage(
            "Buradan OPML dosyalarını içe aktarabilir, ayarları açabilir ya da tüm podcastleri aynı anda yenileyebilirsin."),
        "featureDiscoveryPlaylist": MessageLookupByLibrary.simpleMessage(
            "Çalma listesini açmak için dokun"),
        "featureDiscoveryPlaylistDes": MessageLookupByLibrary.simpleMessage(
            "Çalma listelerine bölüm ekleyebilirsin. Bölümler oynatıldığında çalma listelerinden otomatik olarak silinir."),
        "featureDiscoveryPodcast":
            MessageLookupByLibrary.simpleMessage("Podcast görünümü"),
        "featureDiscoveryPodcastDes": MessageLookupByLibrary.simpleMessage(
            "Grup eklemek veya düzenlemek için Hepsini Gör\'e dokun."),
        "featureDiscoveryPodcastTitle": MessageLookupByLibrary.simpleMessage(
            "Grup değiştirmek için dikey kaydır"),
        "featureDiscoverySearch": MessageLookupByLibrary.simpleMessage(
            "Podcast aramak için buraya dokun"),
        "featureDiscoverySearchDes": MessageLookupByLibrary.simpleMessage(
            "Podcast adı, RSS linki, veya bir kaç harf girerek yeni podcast arayabilirsin."),
        "feedbackEmail": MessageLookupByLibrary.simpleMessage("İletişim"),
        "feedbackGithub": MessageLookupByLibrary.simpleMessage("Sorun bildir"),
        "feedbackPlay":
            MessageLookupByLibrary.simpleMessage("Play Store\'da oyla"),
        "feedbackTelegram": MessageLookupByLibrary.simpleMessage("Gruba katıl"),
        "filter": MessageLookupByLibrary.simpleMessage("Filtrele"),
        "filterType": m32,
        "fontStyle": MessageLookupByLibrary.simpleMessage("Yazı tipi stili"),
        "fonts": MessageLookupByLibrary.simpleMessage("Yazı tipleri"),
        "forward": MessageLookupByLibrary.simpleMessage("İleri"),
        "from": m7,
        "getStarted": MessageLookupByLibrary.simpleMessage("Başlamak için"),
        "getStartedDes": m33,
        "globallyDisabled":
            MessageLookupByLibrary.simpleMessage("Küresel olarak devre dışı"),
        "goodNight": MessageLookupByLibrary.simpleMessage("İyi Geceler"),
        "gpodderLoginDes": MessageLookupByLibrary.simpleMessage(
            "Tebrikler! Gpodder.net hesabınızla bağlantı kuruldu.Tsacdop aboneliklerinizi gpodder.net  hesabınızla otomatik olarak eşitleyecek."),
        "groupExisted":
            MessageLookupByLibrary.simpleMessage("Grup zaten mevcut"),
        "groupRemoveConfirm": MessageLookupByLibrary.simpleMessage(
            "Bu grubu silmek istediğine emin misin? Podcastler \'Home\' grubuna aktarılacaktır."),
        "groups": m8,
        "haptics":
            MessageLookupByLibrary.simpleMessage("Dokunsal Geribildirim"),
        "hapticsDes": MessageLookupByLibrary.simpleMessage(
            "Dokunsal geri bildirimi aç ve yoğunluğunu ayarla. (Cihaz desteği gerektirir)"),
        "hideListenedSetting":
            MessageLookupByLibrary.simpleMessage("Oynatılanları gizle"),
        "hidePodcastDiscovery":
            MessageLookupByLibrary.simpleMessage("Podcast önerilerini gizle"),
        "hidePodcastDiscoveryDes": MessageLookupByLibrary.simpleMessage(
            "Podcast önerilerini arama sayfasında gösterme"),
        "homeGroupsSeeAll": MessageLookupByLibrary.simpleMessage("Hepsini Gör"),
        "homeMenuPlaylist":
            MessageLookupByLibrary.simpleMessage("Çalma listesi"),
        "homeSubMenuSortBy": MessageLookupByLibrary.simpleMessage("Sıralama"),
        "homeTabMenuFavotite": MessageLookupByLibrary.simpleMessage("Favori"),
        "homeTabMenuRecent":
            MessageLookupByLibrary.simpleMessage("Son yayınlar"),
        "homeToprightMenuAbout":
            MessageLookupByLibrary.simpleMessage("Hakkında"),
        "homeToprightMenuImportOMPL":
            MessageLookupByLibrary.simpleMessage("OPML içe aktar"),
        "homeToprightMenuRefreshAll":
            MessageLookupByLibrary.simpleMessage("Hepsini yenile"),
        "hostedOn": m0,
        "hoursAgo": m9,
        "hoursCount": m10,
        "import": MessageLookupByLibrary.simpleMessage("İçe aktar"),
        "importingOpml": MessageLookupByLibrary.simpleMessage(
            "OPML dosyası içeri alınıyor."),
        "interaction": MessageLookupByLibrary.simpleMessage("Etkileşim"),
        "intergateWith": m11,
        "introFourthPage": MessageLookupByLibrary.simpleMessage(
            "Bölüm resmine uzun basarak hızlı menüyü açabilirsin."),
        "introSecondPage": MessageLookupByLibrary.simpleMessage(
            "Arama yaparak ya da OPML dosyasını içe aktararak podcaste abone olabilirsin."),
        "introThirdPage": MessageLookupByLibrary.simpleMessage(
            "Podcastler için yeni bir grup oluşturabilirsin."),
        "invalidName":
            MessageLookupByLibrary.simpleMessage("Geçersiz kullanıcı adı"),
        "keepAndroidOpen": MessageLookupByLibrary.simpleMessage(
            "Google, telefonunuza hangi uygulamaları yükleyebileceğinizi kontrol etmek istiyor."),
        "keepAndroidOpenDes": MessageLookupByLibrary.simpleMessage(
            "keepandroidopen.org\'da daha fazla bilgi edinin ve sesinizi duyurun."),
        "lastUpdate": MessageLookupByLibrary.simpleMessage("Son güncelleme"),
        "later": MessageLookupByLibrary.simpleMessage("Sonra"),
        "lightMode": MessageLookupByLibrary.simpleMessage("Aydınlık mod"),
        "like": MessageLookupByLibrary.simpleMessage("Beğen"),
        "likeDate": MessageLookupByLibrary.simpleMessage("Beğenilme tarihi"),
        "liked": MessageLookupByLibrary.simpleMessage("Beğenilen"),
        "listen": MessageLookupByLibrary.simpleMessage("Dinle"),
        "listened": MessageLookupByLibrary.simpleMessage("Oynatılan"),
        "loadAllSelected":
            MessageLookupByLibrary.simpleMessage("Tüm Seçilenleri Yükle"),
        "loadMore": MessageLookupByLibrary.simpleMessage("Daha fazla göster"),
        "loading": MessageLookupByLibrary.simpleMessage("Yükleniyor"),
        "localEpisodeDescription": m34,
        "localFolder": MessageLookupByLibrary.simpleMessage("Yerel Klasör"),
        "localFolderDescription": MessageLookupByLibrary.simpleMessage(
            "İçeri alınmış yerel ses dosyalarını toplayan kukla podcast."),
        "localizationWeblate": MessageLookupByLibrary.simpleMessage(
            "Bu uygulamanın çervrilmesine açık kaynaklı uygulamalara sundukları destek sayesinde Hosted Weblate\'te katkıda bulunabilirsiniz."),
        "loggedInAs": m1,
        "login": MessageLookupByLibrary.simpleMessage("Giriş"),
        "loginFailed": MessageLookupByLibrary.simpleMessage("Giriş başarısız"),
        "logout": MessageLookupByLibrary.simpleMessage("Çıkış yap"),
        "mark": MessageLookupByLibrary.simpleMessage("İşaretle"),
        "markConfirm": MessageLookupByLibrary.simpleMessage("Seçimi onayla"),
        "markConfirmContent": MessageLookupByLibrary.simpleMessage(
            "Tüm bölümler oynatıldı olarak işaretlensin mi?"),
        "markListened":
            MessageLookupByLibrary.simpleMessage("Oynatıldı olarak işaretle"),
        "markNotListened":
            MessageLookupByLibrary.simpleMessage("Oynatılmadı olarak işaretle"),
        "menu": MessageLookupByLibrary.simpleMessage("Menü"),
        "menuAllPodcasts":
            MessageLookupByLibrary.simpleMessage("Tüm podcastler"),
        "menuMarkAllListened": MessageLookupByLibrary.simpleMessage(
            "Hepsini oynatıldı olarak işaretle"),
        "menuViewRSS":
            MessageLookupByLibrary.simpleMessage("RSS akışını ziyaret et"),
        "menuVisitSite":
            MessageLookupByLibrary.simpleMessage("Siteyi ziyaret et"),
        "minsAgo": m12,
        "minsCount": m13,
        "mobileData": MessageLookupByLibrary.simpleMessage("Mobil Veri"),
        "monthsCount": m35,
        "moreOptions": MessageLookupByLibrary.simpleMessage("Daha Çok Seçenek"),
        "network": MessageLookupByLibrary.simpleMessage("Bağlantı"),
        "networkErrorDNS":
            MessageLookupByLibrary.simpleMessage("Ağ hatası (DNS sorunu)"),
        "neverAutoUpdate": MessageLookupByLibrary.simpleMessage(
            "Küresel senkronizasyona dahil etme"),
        "neverAutoUpdateDes": MessageLookupByLibrary.simpleMessage(
            "Podcast kendi başına yine de senkronize edilebilir."),
        "newGroup": MessageLookupByLibrary.simpleMessage("Yeni grup oluştur"),
        "newPlain": MessageLookupByLibrary.simpleMessage("Yeni"),
        "newPlaylist":
            MessageLookupByLibrary.simpleMessage("Yeni Çalma Listesi"),
        "newestFirst": MessageLookupByLibrary.simpleMessage("Önce yeniler"),
        "next": MessageLookupByLibrary.simpleMessage("Sonraki"),
        "noEpisodesFound": MessageLookupByLibrary.simpleMessage(
            "Seçili filtrelerle bölüm bulunamadı"),
        "noPodcastGroup":
            MessageLookupByLibrary.simpleMessage("Bu grupta hiç podcast yok"),
        "noShownote": MessageLookupByLibrary.simpleMessage(
            "Bu bölüm için her hangi bir not mevcut değil."),
        "none": MessageLookupByLibrary.simpleMessage("Hiçbiri"),
        "notificaitonFatch": m14,
        "notificationAddingGroups": MessageLookupByLibrary.simpleMessage(
            "Gruplar ekleniyor ve düzenleniyor."),
        "notificationNetworkError": m15,
        "notificationSubscribe": m16,
        "notificationSubscribeExisted": m17,
        "notificationSubscribing":
            MessageLookupByLibrary.simpleMessage("Podcastlere abone olunuyor."),
        "notificationSuccess": m18,
        "notificationUpdate": m19,
        "notificationUpdateError": m20,
        "oldestFirst": MessageLookupByLibrary.simpleMessage("Önce eskiler"),
        "opmlFile": MessageLookupByLibrary.simpleMessage("OPML dosyası"),
        "passwdRequired":
            MessageLookupByLibrary.simpleMessage("Parola gerekli"),
        "password": MessageLookupByLibrary.simpleMessage("Şifre"),
        "pause": MessageLookupByLibrary.simpleMessage("Duraklat"),
        "play": MessageLookupByLibrary.simpleMessage("Oynat"),
        "playNext": MessageLookupByLibrary.simpleMessage("Sonrakini çal"),
        "playNextDes": MessageLookupByLibrary.simpleMessage(
            "Çalma listesinin başına ekle"),
        "playback": MessageLookupByLibrary.simpleMessage("Playback kontrol"),
        "player": MessageLookupByLibrary.simpleMessage("Oynatıcı"),
        "playerHeightMed": MessageLookupByLibrary.simpleMessage("Orta"),
        "playerHeightShort": MessageLookupByLibrary.simpleMessage("Kısa"),
        "playerHeightTall": MessageLookupByLibrary.simpleMessage("Uzun"),
        "playing": MessageLookupByLibrary.simpleMessage("Oynatılıyor"),
        "playlistExists":
            MessageLookupByLibrary.simpleMessage("Çalma listesi zaten var"),
        "playlistNameEmpty":
            MessageLookupByLibrary.simpleMessage("İsimsiz çalma listesi"),
        "playlists": MessageLookupByLibrary.simpleMessage("Çalma listeleri"),
        "plugins": MessageLookupByLibrary.simpleMessage("Eklentiler"),
        "podcast": m21,
        "podcastList": MessageLookupByLibrary.simpleMessage("Podcast Listesi"),
        "podcastSubscribed":
            MessageLookupByLibrary.simpleMessage("Podcaste abone olundu"),
        "popupMenuDownloadDes":
            MessageLookupByLibrary.simpleMessage("Bölümü indir"),
        "popupMenuLaterDes":
            MessageLookupByLibrary.simpleMessage("Bölümü çalma listesine ekle"),
        "popupMenuLikeDes":
            MessageLookupByLibrary.simpleMessage("Bölümü favorilere ekle"),
        "popupMenuMarkDes": MessageLookupByLibrary.simpleMessage(
            "Böümü oynatıdı olarak işaretle"),
        "popupMenuPlayDes": MessageLookupByLibrary.simpleMessage("Bölümü çal"),
        "privacyPolicy":
            MessageLookupByLibrary.simpleMessage("Gizlilik sözleşmesi"),
        "publishDate": MessageLookupByLibrary.simpleMessage("Yayın Tarihi"),
        "published": m22,
        "publishedDaily": MessageLookupByLibrary.simpleMessage("Günlük"),
        "publishedMonthly": MessageLookupByLibrary.simpleMessage("Aylık"),
        "publishedWeekly": MessageLookupByLibrary.simpleMessage("Haftalık"),
        "publishedYearly": MessageLookupByLibrary.simpleMessage("Yıllık"),
        "queue": MessageLookupByLibrary.simpleMessage("Kuyruk"),
        "random": MessageLookupByLibrary.simpleMessage("Rastgele"),
        "recoverSubscribe":
            MessageLookupByLibrary.simpleMessage("Aboneliği kurtar"),
        "refresh": MessageLookupByLibrary.simpleMessage("Yenile"),
        "refreshArtwork":
            MessageLookupByLibrary.simpleMessage("Albüm kapağını güncelle"),
        "remove": MessageLookupByLibrary.simpleMessage("Kaldır"),
        "removeConfirm": MessageLookupByLibrary.simpleMessage("İptal teyidi"),
        "removeDownload": MessageLookupByLibrary.simpleMessage("İndirmeyi Sil"),
        "removeNewMark":
            MessageLookupByLibrary.simpleMessage("Yeni işaretini kaldır"),
        "removePodcastDes": MessageLookupByLibrary.simpleMessage(
            "Aboneliği sonlandırmak istediğine emin misin?"),
        "removedAt": m23,
        "restartAppForEffect": MessageLookupByLibrary.simpleMessage(
            "Değişiklerin etki göstermesi için uygulamayı yeniden başlatın."),
        "satellite": MessageLookupByLibrary.simpleMessage("Uydu"),
        "save": MessageLookupByLibrary.simpleMessage("Kaydet"),
        "schedule": MessageLookupByLibrary.simpleMessage("Program"),
        "scheduleDisabled":
            MessageLookupByLibrary.simpleMessage("Program devre dışı."),
        "scheduleTime": m36,
        "search": MessageLookupByLibrary.simpleMessage("Ara"),
        "searchApi": MessageLookupByLibrary.simpleMessage("Arama Api\'si"),
        "searchEngine": MessageLookupByLibrary.simpleMessage("Arama Motoru"),
        "searchEpisode": MessageLookupByLibrary.simpleMessage("Bölüm ara"),
        "searchHelper": MessageLookupByLibrary.simpleMessage(
            "Bir podcast ismi, bir link ya da bir kaç kelime girin."),
        "searchInstructions": MessageLookupByLibrary.simpleMessage(
            "Bir podcast\'e abone olmak için rss akışı url\'sini girin veya adı ile arama yapıp rss akışını açın."),
        "searchInvalidRss":
            MessageLookupByLibrary.simpleMessage("Geçersiz RSS linki"),
        "searchPodcast": MessageLookupByLibrary.simpleMessage("Podcast ara"),
        "searchWeb": MessageLookupByLibrary.simpleMessage("Web Araması"),
        "secCount": m24,
        "secondsAgo": m25,
        "selectMode": MessageLookupByLibrary.simpleMessage("Seçim Modu"),
        "selected": m26,
        "settingStorage": MessageLookupByLibrary.simpleMessage("Depolama"),
        "settings": MessageLookupByLibrary.simpleMessage("Ayarlar"),
        "settingsAccentColor":
            MessageLookupByLibrary.simpleMessage("Aksan rengi"),
        "settingsAppIntro":
            MessageLookupByLibrary.simpleMessage("Uygulama başlangıcı"),
        "settingsAppearance": MessageLookupByLibrary.simpleMessage("Görünüm"),
        "settingsAppearanceDes":
            MessageLookupByLibrary.simpleMessage("Renkler ve temalar"),
        "settingsAudioCache":
            MessageLookupByLibrary.simpleMessage("Audio cache"),
        "settingsAudioCacheDes":
            MessageLookupByLibrary.simpleMessage("Maksimum audio cache boyutu"),
        "settingsAutoDelete":
            MessageLookupByLibrary.simpleMessage("Otomatik sil"),
        "settingsAutoDeleteAfterPlayed": MessageLookupByLibrary.simpleMessage(
            "Oynatılmış indirilenleri sil"),
        "settingsAutoDeleteAfterTime":
            MessageLookupByLibrary.simpleMessage("Eskiden indirilenleri sil"),
        "settingsAutoDeleteAfterTimeDes": MessageLookupByLibrary.simpleMessage(
            "En az şu kadar eski olanları sil..."),
        "settingsAutoDeleteDes": MessageLookupByLibrary.simpleMessage(
            "Silme işlemleri uygulama açılışı veya senkronizasyon sırasında yapılır."),
        "settingsAutoDeleteOldestIfTotalAbove":
            MessageLookupByLibrary.simpleMessage(
                "İndirilenler depolamasını sınırla"),
        "settingsAutoDeleteOldestIfTotalAboveDes":
            MessageLookupByLibrary.simpleMessage(
                "İndirilen ses dosyalarının toplam büyüklüğü bunu aşıyorsa, en eski indirilenler silinecektir."),
        "settingsAutoDownload":
            MessageLookupByLibrary.simpleMessage("Küresel otomatik indirme"),
        "settingsAutoDownloadDes": MessageLookupByLibrary.simpleMessage(
            "Eğer podcast\'in otomatik indirmesi açıksa senkronizasyondan sonra yeni işaretli bölümlerini indir."),
        "settingsAutoDownloadNewPodcast":
            MessageLookupByLibrary.simpleMessage("Varsayılan otomatik indirme"),
        "settingsAutoDownloadNewPodcastDes": MessageLookupByLibrary.simpleMessage(
            "Yeni abone olunan podcast\'lar için varsayılan otomatik indirme ayarı."),
        "settingsAutoDownloadOnForbidden": MessageLookupByLibrary.simpleMessage(
            "Yasak bağlantılar üzerinden otomatik indir"),
        "settingsAutoDownloadOnForbiddenDes": MessageLookupByLibrary.simpleMessage(
            "Bu ayar kapalı ise, bağlantı yasak iken başlayan otomatik indirmeler anında duraklatılacaktır."),
        "settingsAutoPlayDes": MessageLookupByLibrary.simpleMessage(
            "Şimdiki bölüm bitince sonraki bölümü otomatik oynat."),
        "settingsAutoSync":
            MessageLookupByLibrary.simpleMessage("Otomatik senkronizasyon"),
        "settingsAutoSyncDes": MessageLookupByLibrary.simpleMessage(
            "Son yayınlanan bölümleri edinmek için düzenli olarak tüm podcast\'leri arka planda yenile."),
        "settingsBackup": MessageLookupByLibrary.simpleMessage("Yedekleme"),
        "settingsBackupCategories":
            MessageLookupByLibrary.simpleMessage("Kategoriler"),
        "settingsBackupCategoriesDes": MessageLookupByLibrary.simpleMessage(
            "Dışa aktarılacak, içe aktarılacak veya sıfırlanacak ayar kategorileri."),
        "settingsBackupCategoriesImportDes":
            MessageLookupByLibrary.simpleMessage(
                "İçe aktarılacak ayar kategorileri."),
        "settingsBackupConfirmationDatabaseOverwrite":
            MessageLookupByLibrary.simpleMessage(
                "Seçili veritabanı kategorilerini silmek ve yedekleme ile değiştirmek istediğinizden emin misiniz?"),
        "settingsBackupConfirmationDatabaseReset":
            MessageLookupByLibrary.simpleMessage(
                "Seçili veritabanı kategorilerini sıfırlamak istediğinizden emin misiniz?"),
        "settingsBackupConfirmationSettingsOverwrite":
            MessageLookupByLibrary.simpleMessage(
                "Seçili kategorilerdeki mevcut ayarların üzerine yazmak istediğinizden emin misiniz?"),
        "settingsBackupConfirmationSettingsReset":
            MessageLookupByLibrary.simpleMessage(
                "Seçili kategorilerdeki ayarları varsayılanlara sıfırlamak istediğinizden emin misiniz?"),
        "settingsBackupDatabase":
            MessageLookupByLibrary.simpleMessage("Veritabanı"),
        "settingsBackupDatabaseBackupFile":
            MessageLookupByLibrary.simpleMessage("Veritabanı dosyası"),
        "settingsBackupDatabaseBackupFileDes":
            MessageLookupByLibrary.simpleMessage(
                "Uygulama verilerini dışa aktar, içe aktar veya sıfırla."),
        "settingsBackupDatabaseCategoriesDes": MessageLookupByLibrary.simpleMessage(
            "Dışa aktarılacak, içe aktarılacak veya sıfırlanacak veritabanı kategorileri."),
        "settingsBackupDatabaseHistory":
            MessageLookupByLibrary.simpleMessage("Oynatma ve abonelik geçmişi"),
        "settingsBackupDatabasePlaylists":
            MessageLookupByLibrary.simpleMessage("Çalma listeleri"),
        "settingsBackupDatabasePodcasts": MessageLookupByLibrary.simpleMessage(
            "Podcastler, bölümler ve gruplar"),
        "settingsBackupDes": MessageLookupByLibrary.simpleMessage(
            "Yedekle, geri yükle veya sıfırla"),
        "settingsBackupFile":
            MessageLookupByLibrary.simpleMessage("Ayar Yedekleme Dosyası"),
        "settingsBackupLegacyFile":
            MessageLookupByLibrary.simpleMessage("Eski Ayar Yedekleme Dosyası"),
        "settingsBackupLegacyFileDes": MessageLookupByLibrary.simpleMessage(
            "v0.10\'dan önce yapılmış yedekleri içe aktar."),
        "settingsBackupPassword":
            MessageLookupByLibrary.simpleMessage("Yedekleme Parolası"),
        "settingsBackupPasswordDes": MessageLookupByLibrary.simpleMessage(
            "İsteğe bağlı olarak, yedeklemenin dışa aktarılırken şifrelenmesi veya içe aktarılırken şifresinin açılması için parola."),
        "settingsBoostVolume":
            MessageLookupByLibrary.simpleMessage("Ses yükseltme miktarı"),
        "settingsBoostVolumeDes": MessageLookupByLibrary.simpleMessage(
            "Ses yükseltme açıkken yükseltilecek desibel sayısı."),
        "settingsColors": MessageLookupByLibrary.simpleMessage("Renkler"),
        "settingsDefaultFilterAndroidAuto":
            MessageLookupByLibrary.simpleMessage("Android Auto Filtreleri"),
        "settingsDefaultFilterAndroidAutoDes": MessageLookupByLibrary.simpleMessage(
            "Android Auto\'da görünen kütüphaneye uygulanacak filtreler. Sadece ilk 108 madde gösterilecektir."),
        "settingsDefaultFilters":
            MessageLookupByLibrary.simpleMessage("Varsayılan Filtreler"),
        "settingsDefaultGrid":
            MessageLookupByLibrary.simpleMessage("Varsayılan ızgara görünümü"),
        "settingsDefaultGridDownload":
            MessageLookupByLibrary.simpleMessage("İndirilenler sekmesi"),
        "settingsDefaultGridFavorite":
            MessageLookupByLibrary.simpleMessage("Favoriler sekmesi"),
        "settingsDefaultGridPodcast":
            MessageLookupByLibrary.simpleMessage("Podcastler"),
        "settingsDefaultGridRecent":
            MessageLookupByLibrary.simpleMessage("Son yayınlar sekmesi"),
        "settingsDiscovery": MessageLookupByLibrary.simpleMessage(
            "Keşfet özelliğini yeniden aktifleştir"),
        "settingsDiscoveryDes": MessageLookupByLibrary.simpleMessage(
            "\"Keşif Özellikleri\"ni yeniden açmak istediğinizden emin misiniz?"),
        "settingsDownloadAskOnForbidden": MessageLookupByLibrary.simpleMessage(
            "Yasaklı bir bağlantıda indirme başlatırken sor"),
        "settingsDownloadAskOnForbiddenDes":
            MessageLookupByLibrary.simpleMessage(
                "Onaylanmazsa, indirme başlamayacaktır."),
        "settingsDownloadPosition":
            MessageLookupByLibrary.simpleMessage("İndirme konumu"),
        "settingsDownloads": MessageLookupByLibrary.simpleMessage("İndirmeler"),
        "settingsDownloadsDes": MessageLookupByLibrary.simpleMessage(
            "Otomatik indirme, otomatik silme ve yasak bağlantılar"),
        "settingsEpisodeManagement":
            MessageLookupByLibrary.simpleMessage("Bölüm Yönetimi"),
        "settingsExportDes": MessageLookupByLibrary.simpleMessage(
            "Uygulama ayarlarıını dışa aktar, içe aktar veya sıfırla."),
        "settingsFastForwardSec":
            MessageLookupByLibrary.simpleMessage("İleri sarma saniyesi"),
        "settingsFastForwardSecDes": MessageLookupByLibrary.simpleMessage(
            "Oynatıcıda ileri sarma saniyesini belirle"),
        "settingsFeedback":
            MessageLookupByLibrary.simpleMessage("Geribildirim"),
        "settingsFeedbackDes":
            MessageLookupByLibrary.simpleMessage("Hata bildirimi ve istekler"),
        "settingsForbiddenDownloadConnections":
            MessageLookupByLibrary.simpleMessage(
                "Yasaklı indirme bağlantıları"),
        "settingsForbiddenDownloadConnectionsDes":
            MessageLookupByLibrary.simpleMessage(
                "İndirmeler seçili bağlanılarda yukarıdaki kurallara göre yasaklanacaktır."),
        "settingsGeneral": MessageLookupByLibrary.simpleMessage("Genel"),
        "settingsHistory": MessageLookupByLibrary.simpleMessage("Geçmiş"),
        "settingsHistoryDes":
            MessageLookupByLibrary.simpleMessage("Oynatma bilgileri"),
        "settingsHomeTabAdd":
            MessageLookupByLibrary.simpleMessage("Yeni sekme ekle"),
        "settingsHomeTabName":
            MessageLookupByLibrary.simpleMessage("Sekme adı"),
        "settingsHomeTabNew":
            MessageLookupByLibrary.simpleMessage("Yeni sekme"),
        "settingsHomeTabs":
            MessageLookupByLibrary.simpleMessage("Ev sekmeleri"),
        "settingsInfo": MessageLookupByLibrary.simpleMessage("Bilgi"),
        "settingsInterface": MessageLookupByLibrary.simpleMessage("Ara yüz"),
        "settingsInterfaceDes":
            MessageLookupByLibrary.simpleMessage("Arayüz varsayılanları"),
        "settingsLanguage": MessageLookupByLibrary.simpleMessage("Dil"),
        "settingsLegacy":
            MessageLookupByLibrary.simpleMessage("Ayarlar (Eski)"),
        "settingsLibraries":
            MessageLookupByLibrary.simpleMessage("Kütüphaneler"),
        "settingsLibrariesDes": MessageLookupByLibrary.simpleMessage(
            "Bu uygulamada kullanılann açık kaynak kütüphaneleri"),
        "settingsLookAndFeel":
            MessageLookupByLibrary.simpleMessage("Görünüş ve His"),
        "settingsLookAndFeelDes": MessageLookupByLibrary.simpleMessage(
            "Renkler, yazı tipleri ve titreşimler"),
        "settingsManageDownload":
            MessageLookupByLibrary.simpleMessage("İndirilenleri yönet"),
        "settingsManageDownloadDes": MessageLookupByLibrary.simpleMessage(
            "İndirilen ses dosyalarını yönet"),
        "settingsMarkListenedSkip": MessageLookupByLibrary.simpleMessage(
            "Atladığında oynatıldı olarak işaretle"),
        "settingsMarkListenedSkipDes": MessageLookupByLibrary.simpleMessage(
            "Sonrakine atlandığında şuanki bölümü oynatıldı olarak işaretle."),
        "settingsMediaControls": MessageLookupByLibrary.simpleMessage(
            "Bildirim paneli medya kontrolleri"),
        "settingsMediaControlsDes": MessageLookupByLibrary.simpleMessage(
            "Düğme konumları cihazlar, Android versiyonları ve seçili düğmelere göre değişebilir."),
        "settingsMenuAutoPlay":
            MessageLookupByLibrary.simpleMessage("Sonrakini otomatik oynat"),
        "settingsNetworkCellular": MessageLookupByLibrary.simpleMessage(
            "Hücresel veri kullanmadan önce sor"),
        "settingsNetworkCellularDes": MessageLookupByLibrary.simpleMessage(
            "Hücresel veri ile bölüm indirmek için sor"),
        "settingsNewEpisodes":
            MessageLookupByLibrary.simpleMessage("Yeni Bölümler"),
        "settingsNewEpisodesDes":
            MessageLookupByLibrary.simpleMessage("Yeni bölüm krierleri."),
        "settingsNewEpisodesMark":
            MessageLookupByLibrary.simpleMessage("Yeni bölümleri işaretle"),
        "settingsNewEpisodesMarkAge":
            MessageLookupByLibrary.simpleMessage("Maksimum Yaş"),
        "settingsNewEpisodesMarkAgeDes": MessageLookupByLibrary.simpleMessage(
            "Yayın tarihi şundan daha yeni..."),
        "settingsNewEpisodesMarkDes": MessageLookupByLibrary.simpleMessage(
            "Senkronizasyondan sonra bölümleri yeni olarak işaretleme kriterleri."),
        "settingsNewEpisodesMarkDuplicate":
            MessageLookupByLibrary.simpleMessage("Kopya"),
        "settingsNewEpisodesMarkDuplicateDes":
            MessageLookupByLibrary.simpleMessage(
                "Bölümlerin kopya versiyonları yeni olarak işaretlenebilir."),
        "settingsNewEpisodesMarkNewPodcast":
            MessageLookupByLibrary.simpleMessage("Yeni Podcast"),
        "settingsNewEpisodesMarkNewPodcastDes":
            MessageLookupByLibrary.simpleMessage(
                "Bölümler podcast\'a abone olunurken yeni olarak işaretlenebilir."),
        "settingsNewEpisodesMarkUnseen":
            MessageLookupByLibrary.simpleMessage("Görülmemiş"),
        "settingsNewEpisodesMarkUnseenDes":
            MessageLookupByLibrary.simpleMessage(
                "Bölüm senkronizasyondan önce vertabanında yoktu."),
        "settingsNewEpisodesUnmark": MessageLookupByLibrary.simpleMessage(
            "Yeni bölümlerin işaretini kaldır"),
        "settingsNewEpisodesUnmarkAge":
            MessageLookupByLibrary.simpleMessage("Minimum Yaş"),
        "settingsNewEpisodesUnmarkAgeDes": MessageLookupByLibrary.simpleMessage(
            "Yayın tarihi şundan daha eski..."),
        "settingsNewEpisodesUnmarkDes": MessageLookupByLibrary.simpleMessage(
            "Bölümlerden yeni işaretini otomatik olarak kaldırma kriterleri."),
        "settingsNewEpisodesUnmarkInteracted":
            MessageLookupByLibrary.simpleMessage("Etkileşilmiş"),
        "settingsNewEpisodesUnmarkInteractedDes":
            MessageLookupByLibrary.simpleMessage(
                "Bölümün detyları açılmış veya bölüm seçilmiş."),
        "settingsNewEpisodesUnmarkPlayed":
            MessageLookupByLibrary.simpleMessage("Oynatılmış"),
        "settingsNewEpisodesUnmarkPlayedDes":
            MessageLookupByLibrary.simpleMessage("Bölüm oynatılmış."),
        "settingsNewEpisodesUnmarkWaitSync":
            MessageLookupByLibrary.simpleMessage(
                "Sonraki senkronizasyonu bekle"),
        "settingsNewEpisodesUnmarkWaitSyncDes":
            MessageLookupByLibrary.simpleMessage(
                "Yeni işaretini yalnız senkronizasyon sırasında kaldır."),
        "settingsPauseDownloadOnForbiddenConnected":
            MessageLookupByLibrary.simpleMessage(
                "İndirmeleri bağlantıya göre duraklat ve devam ettir"),
        "settingsPauseDownloadOnForbiddenConnectedDes":
            MessageLookupByLibrary.simpleMessage(
                "Yasaklı bir bağlantıya bağlanılırsa tüm indirmeler duraklatılacaktır. Yasaklı bağlantı sona erince tüm indirmeler devam ettirilecektir."),
        "settingsPlayback": MessageLookupByLibrary.simpleMessage("Oynatma"),
        "settingsPlaybackDes":
            MessageLookupByLibrary.simpleMessage("Oynatma davranışı"),
        "settingsPlayerState":
            MessageLookupByLibrary.simpleMessage("Ses Oynatıcı Durumu"),
        "settingsPopupMenu": MessageLookupByLibrary.simpleMessage(
            "Bölümlerin açılır pencere menüsü"),
        "settingsPopupMenuDes": MessageLookupByLibrary.simpleMessage(
            "Bölümlerin açılır pencere menüsünü değiştir"),
        "settingsPrefrence": MessageLookupByLibrary.simpleMessage("Tercihler"),
        "settingsRequirements":
            MessageLookupByLibrary.simpleMessage("Gereklilikler"),
        "settingsRequirementsAll":
            MessageLookupByLibrary.simpleMessage("Hepsi"),
        "settingsRequirementsAny":
            MessageLookupByLibrary.simpleMessage("Herhangi Biri"),
        "settingsRequirementsDes": MessageLookupByLibrary.simpleMessage(
            "Yukarıdakilere ek, aşağıdakilerin hepsini veya herhangi birini gerektir."),
        "settingsReset": MessageLookupByLibrary.simpleMessage("Sıfırla"),
        "settingsRewindSec":
            MessageLookupByLibrary.simpleMessage("Geri sarma saniyesi"),
        "settingsRewindSecDes": MessageLookupByLibrary.simpleMessage(
            "Oynatıcıda geri sarma saniyesini belirle"),
        "settingsSTAuto":
            MessageLookupByLibrary.simpleMessage("Otomatik uyku zamanlayıcısı"),
        "settingsSTAutoDes": MessageLookupByLibrary.simpleMessage(
            "Uyku zamanlayıcısını programlanan zamanda otomatik başlat."),
        "settingsSTDefaultTime":
            MessageLookupByLibrary.simpleMessage("Varsayılan zaman"),
        "settingsSTDefautTimeDes": MessageLookupByLibrary.simpleMessage(
            "Uyku zamanlayıcısının varsayılan bekleme süresi."),
        "settingsSTMode":
            MessageLookupByLibrary.simpleMessage("Uyku zamanlayıcısı modu"),
        "settingsSTWaitEpisodeEnd":
            MessageLookupByLibrary.simpleMessage("Sonuna kadar oynat"),
        "settingsSTWaitEpisodeEndDes": MessageLookupByLibrary.simpleMessage(
            "Uyku zamanlayıcısı bitince oynatmayı durdurmak için oynayan bölümün sonunu bekle."),
        "settingsSearchApi":
            MessageLookupByLibrary.simpleMessage("Varsayılan arama api\'si"),
        "settingsSearchEngine":
            MessageLookupByLibrary.simpleMessage("Varsayılan ağ arama motoru"),
        "settingsSearchMode":
            MessageLookupByLibrary.simpleMessage("Varsayılan olarak ağı ara"),
        "settingsSpeeds": MessageLookupByLibrary.simpleMessage("Hız"),
        "settingsSpeedsDes":
            MessageLookupByLibrary.simpleMessage("Mevcut hızı ayarla"),
        "settingsSyncing":
            MessageLookupByLibrary.simpleMessage("Senkronizasyon"),
        "settingsSyncingDes": MessageLookupByLibrary.simpleMessage(
            "Podcastleri arka planla güncelle"),
        "settingsSyncingInterval":
            MessageLookupByLibrary.simpleMessage("Senkronizasyon aralığı"),
        "settingsTapToOpenPopupMenu":
            MessageLookupByLibrary.simpleMessage("Menüyü açmak için tıkla"),
        "settingsTapToOpenPopupMenuDes": MessageLookupByLibrary.simpleMessage(
            "Bölüm sayfasını açmak için uzun basmalısın"),
        "settingsTheme": MessageLookupByLibrary.simpleMessage("Tema"),
        "settingsTrueBlack":
            MessageLookupByLibrary.simpleMessage("Gerçek Siyah"),
        "settingsTrueBlackDes":
            MessageLookupByLibrary.simpleMessage("Koyu temada siyah yüzeyler"),
        "settingsUseSystemAccentColor":
            MessageLookupByLibrary.simpleMessage("Sistem aksan rengini kullan"),
        "share": MessageLookupByLibrary.simpleMessage("Paylaş"),
        "showNotesFonts":
            MessageLookupByLibrary.simpleMessage("Not yazı tipini göster"),
        "size": MessageLookupByLibrary.simpleMessage("Boyut"),
        "skipSecondsAtEnd":
            MessageLookupByLibrary.simpleMessage("Sonda atlanacak saniye"),
        "skipSecondsAtStart":
            MessageLookupByLibrary.simpleMessage("Başta atlanacak saniye"),
        "skipSilence": MessageLookupByLibrary.simpleMessage("Boşlukları atla"),
        "skipToNext": MessageLookupByLibrary.simpleMessage("Sonrakine geç"),
        "skipToPrevious": MessageLookupByLibrary.simpleMessage("Öncekine atla"),
        "sleepTimer":
            MessageLookupByLibrary.simpleMessage("Uyku zamanlayıcısı"),
        "sleepTimerCancel":
            MessageLookupByLibrary.simpleMessage("Zamanlayıcıyı iptal et"),
        "sleepTimerExpireAt":
            MessageLookupByLibrary.simpleMessage("Bitme Zamanı"),
        "sleepTimerStart":
            MessageLookupByLibrary.simpleMessage("Zamanlayıcıyı başlat"),
        "sleepTimerWait":
            MessageLookupByLibrary.simpleMessage("Bölümün bitmesi bekleniyor"),
        "sleepTimerWaitFor":
            MessageLookupByLibrary.simpleMessage("Bekleme Zamanı (Dakika)"),
        "sortBy": MessageLookupByLibrary.simpleMessage("Sıralama Ölçütü"),
        "sortOrder": MessageLookupByLibrary.simpleMessage("Sıralama Yönü"),
        "status": MessageLookupByLibrary.simpleMessage("Durum"),
        "statusAuthError":
            MessageLookupByLibrary.simpleMessage("Doğrulama hatası"),
        "statusFail": MessageLookupByLibrary.simpleMessage("Başarısız oldu"),
        "statusSuccess": MessageLookupByLibrary.simpleMessage("Başarılı"),
        "stop": MessageLookupByLibrary.simpleMessage("Dur"),
        "subscribe": MessageLookupByLibrary.simpleMessage("Abone ol"),
        "subscribeExportDes": MessageLookupByLibrary.simpleMessage(
            "Tüm podcastlerin bulunduğu OPML dosyasını içe aktar"),
        "subscribed": MessageLookupByLibrary.simpleMessage("Abone"),
        "suggestName": MessageLookupByLibrary.simpleMessage(
            "Tsacdop-Fork için yeni bir isim öner!"),
        "sync": MessageLookupByLibrary.simpleMessage("Senkronizasyon"),
        "syncFinished":
            MessageLookupByLibrary.simpleMessage("Senkronizasyon bitti"),
        "syncNow": MessageLookupByLibrary.simpleMessage("Senkronize et"),
        "syncStarted":
            MessageLookupByLibrary.simpleMessage("Senkronizasyon başladı"),
        "systemDefault": MessageLookupByLibrary.simpleMessage("Sistemi izle"),
        "timeLastPlayed": m27,
        "timeLeft": m28,
        "to": m29,
        "toastAddPlaylist":
            MessageLookupByLibrary.simpleMessage("Çalma listesine eklendi"),
        "toastBackupRestoreFailure":
            MessageLookupByLibrary.simpleMessage("Yedekleme geri yüklenemedi!"),
        "toastBackupRestoreSuccess":
            MessageLookupByLibrary.simpleMessage("Yedekleme geri yüklendi!"),
        "toastDiscovery": MessageLookupByLibrary.simpleMessage(
            "Keşfet özelliği tekrar etkinleştirildi, lütfen uygulamayı kapatıp açın"),
        "toastFileError": MessageLookupByLibrary.simpleMessage(
            "Dosya hatası, abonelik başarısız"),
        "toastFileNotValid":
            MessageLookupByLibrary.simpleMessage("Dosya geçersiz"),
        "toastHomeGroupNotSupport": MessageLookupByLibrary.simpleMessage(
            "\'Home\' grubu desteklenmiyor"),
        "toastImportSettingsSuccess":
            MessageLookupByLibrary.simpleMessage("Ayarlar başarıyla aktarıldı"),
        "toastOneGroup":
            MessageLookupByLibrary.simpleMessage("En az bir grup seçin"),
        "toastPodcastRecovering": MessageLookupByLibrary.simpleMessage(
            "Kurtarılıyor, lütfen bekleyin"),
        "toastReadFile":
            MessageLookupByLibrary.simpleMessage("Dosya başarıyla okundu"),
        "toastRecoverFailed": MessageLookupByLibrary.simpleMessage(
            "Podcast kurtarma başarısız oldu"),
        "toastRemovePlaylist": MessageLookupByLibrary.simpleMessage(
            "Bölüm çalma listesinden kaldırıldı"),
        "toastResetSuccessful":
            MessageLookupByLibrary.simpleMessage("Sıfırlama başarılı!"),
        "toastRestart": MessageLookupByLibrary.simpleMessage(
            "Lütfen uygulamayı hemen yeniden başlatın."),
        "toastSettingSaved":
            MessageLookupByLibrary.simpleMessage("Ayarlar kaydedildi"),
        "toastTimeEqualEnd":
            MessageLookupByLibrary.simpleMessage("Zaman bitiş zamanına eşit"),
        "toastTimeEqualStart": MessageLookupByLibrary.simpleMessage(
            "Zaman başlangıç zamanına eşit"),
        "translate": MessageLookupByLibrary.simpleMessage("Çeviri yap"),
        "translators": MessageLookupByLibrary.simpleMessage("Çevirmenler"),
        "understood": MessageLookupByLibrary.simpleMessage("Anlaşıldı"),
        "undo": MessageLookupByLibrary.simpleMessage("GERİ AL"),
        "unlike": MessageLookupByLibrary.simpleMessage("Beğenme"),
        "unliked": MessageLookupByLibrary.simpleMessage(
            "Bölüm favorilerden kaldırıldı"),
        "unsupported": MessageLookupByLibrary.simpleMessage("Desteklenmiyor"),
        "updateDate":
            MessageLookupByLibrary.simpleMessage("Güncellenme tarihi"),
        "updateEpisodesCount": m30,
        "updateFailed": MessageLookupByLibrary.simpleMessage(
            "Güncelleme başarısız, bağlantı hatası"),
        "username": MessageLookupByLibrary.simpleMessage("Kullanıcı adı"),
        "usernameRequired":
            MessageLookupByLibrary.simpleMessage("Kullanıcı adı gerekli"),
        "version": m31,
        "vpn": MessageLookupByLibrary.simpleMessage("VPN"),
        "weeksCount": m37,
        "welcome":
            MessageLookupByLibrary.simpleMessage("Tsacdop\'a hoş geldiniz!"),
        "wifi": MessageLookupByLibrary.simpleMessage("Wi-Fi"),
        "yearsCount": m38
      };
}
