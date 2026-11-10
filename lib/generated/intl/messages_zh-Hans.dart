// DO NOT EDIT. This is code generated via package:intl/generate_localized.dart
// This is a library that provides messages for a zh_Hans locale. All the
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
  String get localeName => 'zh_Hans';

  static String m0(groupName, count) =>
      "${Intl.plural(count, zero: '', other: '${groupName}分组${count}集节目添加到播放列表')}";

  static String m1(count) =>
      "${Intl.plural(count, zero: '', other: '${count}集节目添加到播放列表')}";

  static String m2(count) =>
      "${Intl.plural(count, zero: '今天', other: '${count}天前')}";

  static String m3(count) =>
      "${Intl.plural(count, zero: '从不', other: '${count}天')}";

  static String m4(count) => "${Intl.plural(count, zero: '', other: '节目')}";

  static String m5(type) => "";

  static String m6(time) => "自${time}";

  static String m7(icon) => "";

  static String m8(count) => "${Intl.plural(count, zero: '分组', other: '分组')}";

  static String m9(host) => "平台 ${host}";

  static String m10(count) =>
      "${Intl.plural(count, zero: '刚刚', other: '${count}小时前')}";

  static String m11(count) =>
      "${Intl.plural(count, zero: '0小时', other: '${count} 小时')}";

  static String m12(service) => "绑定 ${service}";

  static String m13(filePath) => "";

  static String m14(userName) => "使用${userName}登入";

  static String m15(count) =>
      "${Intl.plural(count, zero: '刚刚', other: '${count}分钟前')}";

  static String m16(count) =>
      "${Intl.plural(count, zero: '0分钟', other: '${count}分钟')}";

  static String m17(count) => "";

  static String m18(title) => "获取数据 ${title}";

  static String m19(title) => "订阅失败，网络错误 ${title}";

  static String m20(title) => "订阅 ${title}";

  static String m21(title) => "订阅失败，播客已存在 ${title}";

  static String m22(title) => "订阅成功 ${title}";

  static String m23(title) => "更新 ${title}";

  static String m24(title) => "更新失败 ${title}";

  static String m25(count) => "${Intl.plural(count, zero: '', other: '播客')}";

  static String m26(date) => "${date}上线";

  static String m27(date) => "${date}移除";

  static String m28(start, end) => "";

  static String m29(count) =>
      "${Intl.plural(count, zero: '0 秒', other: '${count} 秒')}";

  static String m30(count) =>
      "${Intl.plural(count, zero: '刚刚', other: '${count}秒前')}";

  static String m31(count) => "已选择 ${count} 项";

  static String m32(time) => "上次播放${time}";

  static String m33(time) => "剩余 ${time}";

  static String m34(time) => "到${time}";

  static String m35(count) =>
      "${Intl.plural(count, zero: '未有更新', other: '更新 ${count} 集节目')}";

  static String m36(version) => "版本：${version}";

  static String m37(count) => "";

  static String m38(count) => "";

  final messages = _notInlinedMessages(_notInlinedMessages);
  static Map<String, Function> _notInlinedMessages(_) => <String, Function>{
    "aboutDes": MessageLookupByLibrary.simpleMessage(""),
    "add": MessageLookupByLibrary.simpleMessage("订阅"),
    "addEpisodeGroup": m0,
    "addNewEpisodeAll": m1,
    "addNewEpisodeTooltip": MessageLookupByLibrary.simpleMessage("添加更新节目到播放列表"),
    "addSomeGroups": MessageLookupByLibrary.simpleMessage("请添加分组"),
    "after": MessageLookupByLibrary.simpleMessage(""),
    "all": MessageLookupByLibrary.simpleMessage("全部"),
    "apiSearch": MessageLookupByLibrary.simpleMessage(""),
    "autoDownload": MessageLookupByLibrary.simpleMessage("自动下载"),
    "back": MessageLookupByLibrary.simpleMessage("返回"),
    "before": MessageLookupByLibrary.simpleMessage(""),
    "between": MessageLookupByLibrary.simpleMessage(""),
    "boostVolume": MessageLookupByLibrary.simpleMessage("增强声音"),
    "buffering": MessageLookupByLibrary.simpleMessage("缓冲中"),
    "cancel": MessageLookupByLibrary.simpleMessage("取消"),
    "capitalDefault": MessageLookupByLibrary.simpleMessage(""),
    "cellularConfirm": MessageLookupByLibrary.simpleMessage("流量确认"),
    "cellularConfirmDes": MessageLookupByLibrary.simpleMessage("您确定使用流量下载吗"),
    "changeLayout": MessageLookupByLibrary.simpleMessage("修改布局"),
    "changelog": MessageLookupByLibrary.simpleMessage("更新日志"),
    "chooseA": MessageLookupByLibrary.simpleMessage("选择"),
    "clear": MessageLookupByLibrary.simpleMessage("清除"),
    "clearAll": MessageLookupByLibrary.simpleMessage("清除全部"),
    "close": MessageLookupByLibrary.simpleMessage(""),
    "color": MessageLookupByLibrary.simpleMessage("颜色"),
    "confirm": MessageLookupByLibrary.simpleMessage("确认"),
    "confirmation": MessageLookupByLibrary.simpleMessage(""),
    "contribute": MessageLookupByLibrary.simpleMessage(""),
    "createNewPlaylist": MessageLookupByLibrary.simpleMessage("创建播放列表"),
    "darkMode": MessageLookupByLibrary.simpleMessage("夜晚模式"),
    "daysAgo": m2,
    "daysCount": m3,
    "defaultQueueReminder": MessageLookupByLibrary.simpleMessage(
      "此为默认播放列表，无法删除。",
    ),
    "defaultSearchEngine": MessageLookupByLibrary.simpleMessage("默认播客搜索引擎"),
    "defaultSearchEngineDes": MessageLookupByLibrary.simpleMessage(
      "选择默认播客搜索引擎",
    ),
    "delete": MessageLookupByLibrary.simpleMessage("删除"),
    "deleted": MessageLookupByLibrary.simpleMessage(""),
    "deletedEpisodeDesc": MessageLookupByLibrary.simpleMessage(""),
    "deletedPodcastDesc": MessageLookupByLibrary.simpleMessage(""),
    "deselectAll": MessageLookupByLibrary.simpleMessage(""),
    "details": MessageLookupByLibrary.simpleMessage(""),
    "developer": MessageLookupByLibrary.simpleMessage("关于我"),
    "developerOriginal": MessageLookupByLibrary.simpleMessage(""),
    "deviceStorage": MessageLookupByLibrary.simpleMessage(""),
    "disabled": MessageLookupByLibrary.simpleMessage(""),
    "dismiss": MessageLookupByLibrary.simpleMessage("忽略"),
    "displayVersion": MessageLookupByLibrary.simpleMessage(""),
    "done": MessageLookupByLibrary.simpleMessage("完成"),
    "download": MessageLookupByLibrary.simpleMessage("下载"),
    "downloadDate": MessageLookupByLibrary.simpleMessage(""),
    "downloadRemovedToast": MessageLookupByLibrary.simpleMessage("下载已删除"),
    "downloadStart": MessageLookupByLibrary.simpleMessage("下载中"),
    "downloaded": MessageLookupByLibrary.simpleMessage("已下载"),
    "downloading": MessageLookupByLibrary.simpleMessage(""),
    "duration": MessageLookupByLibrary.simpleMessage(""),
    "editGroupName": MessageLookupByLibrary.simpleMessage("修改组名"),
    "endOfEpisode": MessageLookupByLibrary.simpleMessage("节目结束"),
    "episode": m4,
    "fastForward": MessageLookupByLibrary.simpleMessage("快进"),
    "fastRewind": MessageLookupByLibrary.simpleMessage("快退"),
    "featureDiscoveryEditGroup": MessageLookupByLibrary.simpleMessage("点击修改分组"),
    "featureDiscoveryEditGroupDes": MessageLookupByLibrary.simpleMessage(
      "您可以修改分组名或者删除分组，注意 Home 分组无法修改，也不能被删除。",
    ),
    "featureDiscoveryEpisode": MessageLookupByLibrary.simpleMessage("节目界面"),
    "featureDiscoveryEpisodeDes": MessageLookupByLibrary.simpleMessage(
      "您可以长按播放节目或者添加节目到播放列表。",
    ),
    "featureDiscoveryEpisodeTitle": MessageLookupByLibrary.simpleMessage(
      "您可以长按快速播放节目",
    ),
    "featureDiscoveryGroup": MessageLookupByLibrary.simpleMessage("点击添加分组"),
    "featureDiscoveryGroupDes": MessageLookupByLibrary.simpleMessage(
      "新订阅播客默认分组为 Home，您可以添加新的分组，移动播客到新的分组，每个播客可以被添加到多个分组。",
    ),
    "featureDiscoveryGroupPodcast": MessageLookupByLibrary.simpleMessage(
      "长按可以移动播客位置",
    ),
    "featureDiscoveryGroupPodcastDes": MessageLookupByLibrary.simpleMessage(
      "您可以点击对播客进行设置，或者长按重新排序。",
    ),
    "featureDiscoveryOMPL": MessageLookupByLibrary.simpleMessage("点击导入 OPML"),
    "featureDiscoveryOMPLDes": MessageLookupByLibrary.simpleMessage(
      "在这里您可以导入OPML文件，打开设置页面，或者刷新所有播客。",
    ),
    "featureDiscoveryPlaylist": MessageLookupByLibrary.simpleMessage(
      "点击打开播放列表",
    ),
    "featureDiscoveryPlaylistDes": MessageLookupByLibrary.simpleMessage(
      "您可以添加节目到播放列表，节目在播放后将会从播放列表自动移除。",
    ),
    "featureDiscoveryPodcast": MessageLookupByLibrary.simpleMessage("播客界面"),
    "featureDiscoveryPodcastDes": MessageLookupByLibrary.simpleMessage(
      "您可以点击“查看所有”新增或管理分组。",
    ),
    "featureDiscoveryPodcastTitle": MessageLookupByLibrary.simpleMessage(
      "您可以通过上下滑动切换分组",
    ),
    "featureDiscoverySearch": MessageLookupByLibrary.simpleMessage("点击搜索播客"),
    "featureDiscoverySearchDes": MessageLookupByLibrary.simpleMessage(
      "您可以通过搜索播客名称、关键字或者RSS链接订阅播客。",
    ),
    "feedbackEmail": MessageLookupByLibrary.simpleMessage("发送邮件"),
    "feedbackGithub": MessageLookupByLibrary.simpleMessage("提交Issue"),
    "feedbackPlay": MessageLookupByLibrary.simpleMessage("Play评价"),
    "feedbackTelegram": MessageLookupByLibrary.simpleMessage("加入小组"),
    "filter": MessageLookupByLibrary.simpleMessage("过滤"),
    "filterType": m5,
    "fontStyle": MessageLookupByLibrary.simpleMessage("字体风格"),
    "fonts": MessageLookupByLibrary.simpleMessage("字体"),
    "forward": MessageLookupByLibrary.simpleMessage(""),
    "from": m6,
    "getStarted": MessageLookupByLibrary.simpleMessage(""),
    "getStartedDes": m7,
    "globallyDisabled": MessageLookupByLibrary.simpleMessage(""),
    "goodNight": MessageLookupByLibrary.simpleMessage("晚安"),
    "gpodderLoginDes": MessageLookupByLibrary.simpleMessage(
      "恭喜！您已经成功绑定 gpodder.net 账号，Tsacdop 将会自动同步您的订阅到 gpodder.net 账户。",
    ),
    "groupExisted": MessageLookupByLibrary.simpleMessage("组名已使用"),
    "groupRemoveConfirm": MessageLookupByLibrary.simpleMessage(
      "您确认要移除该分组吗？播客将被移动到 Home 分组。",
    ),
    "groups": m8,
    "haptics": MessageLookupByLibrary.simpleMessage(""),
    "hapticsDes": MessageLookupByLibrary.simpleMessage(""),
    "hideListenedSetting": MessageLookupByLibrary.simpleMessage("隐藏已收听"),
    "hidePodcastDiscovery": MessageLookupByLibrary.simpleMessage("隐藏播客推荐"),
    "hidePodcastDiscoveryDes": MessageLookupByLibrary.simpleMessage(
      "在搜索页面隐藏播客推荐",
    ),
    "homeGroupsSeeAll": MessageLookupByLibrary.simpleMessage("查看全部"),
    "homeMenuPlaylist": MessageLookupByLibrary.simpleMessage("播放列表"),
    "homeSubMenuSortBy": MessageLookupByLibrary.simpleMessage("排序"),
    "homeTabMenuFavotite": MessageLookupByLibrary.simpleMessage("收藏"),
    "homeTabMenuRecent": MessageLookupByLibrary.simpleMessage("最近更新"),
    "homeToprightMenuAbout": MessageLookupByLibrary.simpleMessage("关于"),
    "homeToprightMenuImportOMPL": MessageLookupByLibrary.simpleMessage(
      "导入OPML",
    ),
    "homeToprightMenuRefreshAll": MessageLookupByLibrary.simpleMessage("全部刷新"),
    "hostedOn": m9,
    "hoursAgo": m10,
    "hoursCount": m11,
    "import": MessageLookupByLibrary.simpleMessage("导入"),
    "importingOpml": MessageLookupByLibrary.simpleMessage(""),
    "interaction": MessageLookupByLibrary.simpleMessage(""),
    "intergateWith": m12,
    "introFourthPage": MessageLookupByLibrary.simpleMessage("您可以长按节目打开快捷菜单。"),
    "introSecondPage": MessageLookupByLibrary.simpleMessage(
      "您可以通过搜索订阅播客，也可以直接导入OPML文件。",
    ),
    "introThirdPage": MessageLookupByLibrary.simpleMessage("您可以创建分组，上下滑动切换分组。"),
    "invalidName": MessageLookupByLibrary.simpleMessage("用户名错误"),
    "keepAndroidOpen": MessageLookupByLibrary.simpleMessage(""),
    "keepAndroidOpenDes": MessageLookupByLibrary.simpleMessage(""),
    "lastUpdate": MessageLookupByLibrary.simpleMessage("最近更新"),
    "later": MessageLookupByLibrary.simpleMessage("稍后"),
    "lightMode": MessageLookupByLibrary.simpleMessage("明亮模式"),
    "like": MessageLookupByLibrary.simpleMessage("喜欢"),
    "likeDate": MessageLookupByLibrary.simpleMessage("收藏日期"),
    "liked": MessageLookupByLibrary.simpleMessage("已收藏"),
    "listen": MessageLookupByLibrary.simpleMessage("收听"),
    "listened": MessageLookupByLibrary.simpleMessage("已收听"),
    "loadAllSelected": MessageLookupByLibrary.simpleMessage(""),
    "loadMore": MessageLookupByLibrary.simpleMessage("加载更多"),
    "loading": MessageLookupByLibrary.simpleMessage(""),
    "localEpisodeDescription": m13,
    "localFolder": MessageLookupByLibrary.simpleMessage(""),
    "localFolderDescription": MessageLookupByLibrary.simpleMessage(""),
    "localizationWeblate": MessageLookupByLibrary.simpleMessage(""),
    "loggedInAs": m14,
    "login": MessageLookupByLibrary.simpleMessage("登入"),
    "loginFailed": MessageLookupByLibrary.simpleMessage("登入失败"),
    "logout": MessageLookupByLibrary.simpleMessage("注销"),
    "mark": MessageLookupByLibrary.simpleMessage("标记"),
    "markConfirm": MessageLookupByLibrary.simpleMessage("确认标记"),
    "markConfirmContent": MessageLookupByLibrary.simpleMessage(
      "是否确认标记全部节目为已收听？",
    ),
    "markListened": MessageLookupByLibrary.simpleMessage("标记已收听"),
    "markNotListened": MessageLookupByLibrary.simpleMessage("标记为未收听"),
    "menu": MessageLookupByLibrary.simpleMessage("菜单"),
    "menuAllPodcasts": MessageLookupByLibrary.simpleMessage("所有订阅"),
    "menuMarkAllListened": MessageLookupByLibrary.simpleMessage("标记所有已收听"),
    "menuViewRSS": MessageLookupByLibrary.simpleMessage("查看 RSS"),
    "menuVisitSite": MessageLookupByLibrary.simpleMessage("访问网站"),
    "minsAgo": m15,
    "minsCount": m16,
    "mobileData": MessageLookupByLibrary.simpleMessage(""),
    "monthsCount": m17,
    "moreOptions": MessageLookupByLibrary.simpleMessage(""),
    "network": MessageLookupByLibrary.simpleMessage("网络"),
    "networkErrorDNS": MessageLookupByLibrary.simpleMessage(""),
    "neverAutoUpdate": MessageLookupByLibrary.simpleMessage("无需自动更新"),
    "neverAutoUpdateDes": MessageLookupByLibrary.simpleMessage(""),
    "newGroup": MessageLookupByLibrary.simpleMessage("创建分组"),
    "newPlain": MessageLookupByLibrary.simpleMessage(""),
    "newPlaylist": MessageLookupByLibrary.simpleMessage(""),
    "newestFirst": MessageLookupByLibrary.simpleMessage("由新到旧"),
    "next": MessageLookupByLibrary.simpleMessage("下一步"),
    "noEpisodesFound": MessageLookupByLibrary.simpleMessage(""),
    "noPodcastGroup": MessageLookupByLibrary.simpleMessage("分组无播客"),
    "noShownote": MessageLookupByLibrary.simpleMessage("节目简介暂未收到。"),
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
    "oldestFirst": MessageLookupByLibrary.simpleMessage("由旧到新"),
    "opmlFile": MessageLookupByLibrary.simpleMessage(""),
    "passwdRequired": MessageLookupByLibrary.simpleMessage("密码为空"),
    "password": MessageLookupByLibrary.simpleMessage("密码"),
    "pause": MessageLookupByLibrary.simpleMessage("暂停"),
    "play": MessageLookupByLibrary.simpleMessage("播放"),
    "playNext": MessageLookupByLibrary.simpleMessage("下一首"),
    "playNextDes": MessageLookupByLibrary.simpleMessage("添加节目到播放列表的顶部"),
    "playback": MessageLookupByLibrary.simpleMessage("播放控制"),
    "player": MessageLookupByLibrary.simpleMessage("播放器"),
    "playerHeightMed": MessageLookupByLibrary.simpleMessage("中"),
    "playerHeightShort": MessageLookupByLibrary.simpleMessage("低"),
    "playerHeightTall": MessageLookupByLibrary.simpleMessage("高"),
    "playing": MessageLookupByLibrary.simpleMessage("正在播放"),
    "playlistExists": MessageLookupByLibrary.simpleMessage(""),
    "playlistNameEmpty": MessageLookupByLibrary.simpleMessage("播放列表名为空"),
    "playlists": MessageLookupByLibrary.simpleMessage("播放列表"),
    "plugins": MessageLookupByLibrary.simpleMessage("插件"),
    "podcast": m25,
    "podcastList": MessageLookupByLibrary.simpleMessage(""),
    "podcastSubscribed": MessageLookupByLibrary.simpleMessage("播客已订阅"),
    "popupMenuDownloadDes": MessageLookupByLibrary.simpleMessage("下载节目"),
    "popupMenuLaterDes": MessageLookupByLibrary.simpleMessage("添加到播放列表"),
    "popupMenuLikeDes": MessageLookupByLibrary.simpleMessage("添加到收藏"),
    "popupMenuMarkDes": MessageLookupByLibrary.simpleMessage("设置为已收听"),
    "popupMenuPlayDes": MessageLookupByLibrary.simpleMessage("播放节目"),
    "privacyPolicy": MessageLookupByLibrary.simpleMessage("隐私条款"),
    "publishDate": MessageLookupByLibrary.simpleMessage(""),
    "published": m26,
    "publishedDaily": MessageLookupByLibrary.simpleMessage("每日更新"),
    "publishedMonthly": MessageLookupByLibrary.simpleMessage("每月更新"),
    "publishedWeekly": MessageLookupByLibrary.simpleMessage("每周更新"),
    "publishedYearly": MessageLookupByLibrary.simpleMessage("每年更新"),
    "queue": MessageLookupByLibrary.simpleMessage("队列"),
    "random": MessageLookupByLibrary.simpleMessage(""),
    "recoverSubscribe": MessageLookupByLibrary.simpleMessage("恢复订阅"),
    "refresh": MessageLookupByLibrary.simpleMessage("刷新"),
    "refreshArtwork": MessageLookupByLibrary.simpleMessage("更新头像"),
    "remove": MessageLookupByLibrary.simpleMessage("移除"),
    "removeConfirm": MessageLookupByLibrary.simpleMessage("取消订阅"),
    "removeDownload": MessageLookupByLibrary.simpleMessage(""),
    "removeNewMark": MessageLookupByLibrary.simpleMessage("移除New标记"),
    "removePodcastDes": MessageLookupByLibrary.simpleMessage("您确认要取消订阅吗？"),
    "removedAt": m27,
    "restartAppForEffect": MessageLookupByLibrary.simpleMessage(""),
    "satellite": MessageLookupByLibrary.simpleMessage(""),
    "save": MessageLookupByLibrary.simpleMessage("保存"),
    "schedule": MessageLookupByLibrary.simpleMessage("定时"),
    "scheduleDisabled": MessageLookupByLibrary.simpleMessage(""),
    "scheduleTime": m28,
    "search": MessageLookupByLibrary.simpleMessage("搜索"),
    "searchApi": MessageLookupByLibrary.simpleMessage(""),
    "searchEngine": MessageLookupByLibrary.simpleMessage(""),
    "searchEpisode": MessageLookupByLibrary.simpleMessage("搜索节目"),
    "searchHelper": MessageLookupByLibrary.simpleMessage("请输入播客名，关键字或者RSS链接。"),
    "searchInstructions": MessageLookupByLibrary.simpleMessage(""),
    "searchInvalidRss": MessageLookupByLibrary.simpleMessage("RSS 链接错误"),
    "searchPodcast": MessageLookupByLibrary.simpleMessage("搜索播客"),
    "searchWeb": MessageLookupByLibrary.simpleMessage(""),
    "secCount": m29,
    "secondsAgo": m30,
    "selectMode": MessageLookupByLibrary.simpleMessage(""),
    "selected": m31,
    "settingStorage": MessageLookupByLibrary.simpleMessage("储存空间"),
    "settings": MessageLookupByLibrary.simpleMessage("设置"),
    "settingsAccentColor": MessageLookupByLibrary.simpleMessage("次要颜色"),
    "settingsAppIntro": MessageLookupByLibrary.simpleMessage("引导页"),
    "settingsAppearance": MessageLookupByLibrary.simpleMessage("界面"),
    "settingsAppearanceDes": MessageLookupByLibrary.simpleMessage("颜色与主题"),
    "settingsAudioCache": MessageLookupByLibrary.simpleMessage("播放缓存"),
    "settingsAudioCacheDes": MessageLookupByLibrary.simpleMessage("播放缓存设置"),
    "settingsAutoDelete": MessageLookupByLibrary.simpleMessage("自动删除下载节目"),
    "settingsAutoDeleteAfterPlayed": MessageLookupByLibrary.simpleMessage(""),
    "settingsAutoDeleteAfterTime": MessageLookupByLibrary.simpleMessage(""),
    "settingsAutoDeleteAfterTimeDes": MessageLookupByLibrary.simpleMessage(""),
    "settingsAutoDeleteDes": MessageLookupByLibrary.simpleMessage("默认 30 天"),
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
    "settingsAutoPlayDes": MessageLookupByLibrary.simpleMessage("自动播放下一节目"),
    "settingsAutoSync": MessageLookupByLibrary.simpleMessage(""),
    "settingsAutoSyncDes": MessageLookupByLibrary.simpleMessage(""),
    "settingsBackup": MessageLookupByLibrary.simpleMessage("备份"),
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
    "settingsBackupDes": MessageLookupByLibrary.simpleMessage("备份应用数据"),
    "settingsBackupFile": MessageLookupByLibrary.simpleMessage(""),
    "settingsBackupLegacyFile": MessageLookupByLibrary.simpleMessage(""),
    "settingsBackupLegacyFileDes": MessageLookupByLibrary.simpleMessage(""),
    "settingsBackupPassword": MessageLookupByLibrary.simpleMessage(""),
    "settingsBackupPasswordDes": MessageLookupByLibrary.simpleMessage(""),
    "settingsBoostVolume": MessageLookupByLibrary.simpleMessage("声音增强水平"),
    "settingsBoostVolumeDes": MessageLookupByLibrary.simpleMessage("修改声音增强水平"),
    "settingsColors": MessageLookupByLibrary.simpleMessage(""),
    "settingsDefaultFilterAndroidAuto": MessageLookupByLibrary.simpleMessage(
      "",
    ),
    "settingsDefaultFilterAndroidAutoDes": MessageLookupByLibrary.simpleMessage(
      "",
    ),
    "settingsDefaultFilters": MessageLookupByLibrary.simpleMessage(""),
    "settingsDefaultGrid": MessageLookupByLibrary.simpleMessage("默认布局"),
    "settingsDefaultGridDownload": MessageLookupByLibrary.simpleMessage("下载页"),
    "settingsDefaultGridFavorite": MessageLookupByLibrary.simpleMessage("收藏页"),
    "settingsDefaultGridPodcast": MessageLookupByLibrary.simpleMessage("播客页"),
    "settingsDefaultGridRecent": MessageLookupByLibrary.simpleMessage("最近页"),
    "settingsDiscovery": MessageLookupByLibrary.simpleMessage("再次功能介绍"),
    "settingsDiscoveryDes": MessageLookupByLibrary.simpleMessage(""),
    "settingsDownloadAskOnForbidden": MessageLookupByLibrary.simpleMessage(""),
    "settingsDownloadAskOnForbiddenDes": MessageLookupByLibrary.simpleMessage(
      "",
    ),
    "settingsDownloadPosition": MessageLookupByLibrary.simpleMessage("下载位置"),
    "settingsDownloads": MessageLookupByLibrary.simpleMessage(""),
    "settingsDownloadsDes": MessageLookupByLibrary.simpleMessage(""),
    "settingsEpisodeManagement": MessageLookupByLibrary.simpleMessage(""),
    "settingsExportDes": MessageLookupByLibrary.simpleMessage("导出及恢复所有设置项"),
    "settingsFastForwardSec": MessageLookupByLibrary.simpleMessage("快进时间"),
    "settingsFastForwardSecDes": MessageLookupByLibrary.simpleMessage(
      "修改播放器快进时间",
    ),
    "settingsFeedback": MessageLookupByLibrary.simpleMessage("反馈"),
    "settingsFeedbackDes": MessageLookupByLibrary.simpleMessage("意见与建议"),
    "settingsForbiddenDownloadConnections":
        MessageLookupByLibrary.simpleMessage(""),
    "settingsForbiddenDownloadConnectionsDes":
        MessageLookupByLibrary.simpleMessage(""),
    "settingsFullStop": MessageLookupByLibrary.simpleMessage(""),
    "settingsFullStopDes": MessageLookupByLibrary.simpleMessage(""),
    "settingsGeneral": MessageLookupByLibrary.simpleMessage(""),
    "settingsHistory": MessageLookupByLibrary.simpleMessage("历史记录"),
    "settingsHistoryDes": MessageLookupByLibrary.simpleMessage("收听记录"),
    "settingsHomeTabAdd": MessageLookupByLibrary.simpleMessage(""),
    "settingsHomeTabName": MessageLookupByLibrary.simpleMessage(""),
    "settingsHomeTabNew": MessageLookupByLibrary.simpleMessage(""),
    "settingsHomeTabs": MessageLookupByLibrary.simpleMessage(""),
    "settingsInfo": MessageLookupByLibrary.simpleMessage("信息"),
    "settingsInterface": MessageLookupByLibrary.simpleMessage("界面"),
    "settingsInterfaceDes": MessageLookupByLibrary.simpleMessage(""),
    "settingsLanguage": MessageLookupByLibrary.simpleMessage(""),
    "settingsLegacy": MessageLookupByLibrary.simpleMessage(""),
    "settingsLibraries": MessageLookupByLibrary.simpleMessage("开源"),
    "settingsLibrariesDes": MessageLookupByLibrary.simpleMessage("开源项目使用"),
    "settingsLookAndFeel": MessageLookupByLibrary.simpleMessage(""),
    "settingsLookAndFeelDes": MessageLookupByLibrary.simpleMessage(""),
    "settingsManageDownload": MessageLookupByLibrary.simpleMessage("下载管理"),
    "settingsManageDownloadDes": MessageLookupByLibrary.simpleMessage(
      "管理下载节目文件",
    ),
    "settingsManufacturerNotificationLayout":
        MessageLookupByLibrary.simpleMessage(""),
    "settingsMarkListenedSkip": MessageLookupByLibrary.simpleMessage(
      "跳过后标记为已收听",
    ),
    "settingsMarkListenedSkipDes": MessageLookupByLibrary.simpleMessage(
      "当节目被跳过时自动标记为已收听",
    ),
    "settingsMediaControls": MessageLookupByLibrary.simpleMessage(""),
    "settingsMediaControlsDes": MessageLookupByLibrary.simpleMessage(""),
    "settingsMenuAutoPlay": MessageLookupByLibrary.simpleMessage("自动播放下一节目"),
    "settingsNetworkCellular": MessageLookupByLibrary.simpleMessage("蜂窝数据确认"),
    "settingsNetworkCellularDes": MessageLookupByLibrary.simpleMessage(
      "在使用蜂窝数据下载前确认",
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
    "settingsPopupMenu": MessageLookupByLibrary.simpleMessage("节目弹出菜单"),
    "settingsPopupMenuDes": MessageLookupByLibrary.simpleMessage("修改节目弹出菜单"),
    "settingsPrefrence": MessageLookupByLibrary.simpleMessage("首选项"),
    "settingsRequirements": MessageLookupByLibrary.simpleMessage(""),
    "settingsRequirementsAll": MessageLookupByLibrary.simpleMessage(""),
    "settingsRequirementsAny": MessageLookupByLibrary.simpleMessage(""),
    "settingsRequirementsDes": MessageLookupByLibrary.simpleMessage(""),
    "settingsReset": MessageLookupByLibrary.simpleMessage(""),
    "settingsRewindSec": MessageLookupByLibrary.simpleMessage("快退时间"),
    "settingsRewindSecDes": MessageLookupByLibrary.simpleMessage("修改播放器快退时间"),
    "settingsSTAuto": MessageLookupByLibrary.simpleMessage("自动睡眠模式"),
    "settingsSTAutoDes": MessageLookupByLibrary.simpleMessage("定期开启睡眠模式"),
    "settingsSTDefaultTime": MessageLookupByLibrary.simpleMessage("默认时长"),
    "settingsSTDefautTimeDes": MessageLookupByLibrary.simpleMessage("睡眠模式默认时长"),
    "settingsSTMode": MessageLookupByLibrary.simpleMessage("自动睡眠模式默认时长"),
    "settingsSTWaitEpisodeEnd": MessageLookupByLibrary.simpleMessage(""),
    "settingsSTWaitEpisodeEndDes": MessageLookupByLibrary.simpleMessage(""),
    "settingsSearchApi": MessageLookupByLibrary.simpleMessage(""),
    "settingsSearchEngine": MessageLookupByLibrary.simpleMessage(""),
    "settingsSearchMode": MessageLookupByLibrary.simpleMessage(""),
    "settingsSpeeds": MessageLookupByLibrary.simpleMessage("播放速度"),
    "settingsSpeedsDes": MessageLookupByLibrary.simpleMessage("设置播放速度选项"),
    "settingsSyncing": MessageLookupByLibrary.simpleMessage("同步"),
    "settingsSyncingDes": MessageLookupByLibrary.simpleMessage("在后台更新播客"),
    "settingsSyncingInterval": MessageLookupByLibrary.simpleMessage(""),
    "settingsTapToOpenPopupMenu": MessageLookupByLibrary.simpleMessage(
      "轻点打开弹出菜单",
    ),
    "settingsTapToOpenPopupMenuDes": MessageLookupByLibrary.simpleMessage(
      "开启后您需长按打开节目页",
    ),
    "settingsTheme": MessageLookupByLibrary.simpleMessage("主题"),
    "settingsTrueBlack": MessageLookupByLibrary.simpleMessage(""),
    "settingsTrueBlackDes": MessageLookupByLibrary.simpleMessage(""),
    "settingsUseSystemAccentColor": MessageLookupByLibrary.simpleMessage(""),
    "share": MessageLookupByLibrary.simpleMessage("分享"),
    "showNotesFonts": MessageLookupByLibrary.simpleMessage("节目简介字体"),
    "size": MessageLookupByLibrary.simpleMessage("大小"),
    "skipSecondsAtEnd": MessageLookupByLibrary.simpleMessage("结束跳过秒数"),
    "skipSecondsAtStart": MessageLookupByLibrary.simpleMessage("开头跳过秒数"),
    "skipSilence": MessageLookupByLibrary.simpleMessage("跳过无声"),
    "skipToNext": MessageLookupByLibrary.simpleMessage("下一首"),
    "skipToPrevious": MessageLookupByLibrary.simpleMessage(""),
    "sleepTimer": MessageLookupByLibrary.simpleMessage("睡眠模式"),
    "sleepTimerCancel": MessageLookupByLibrary.simpleMessage(""),
    "sleepTimerExpireAt": MessageLookupByLibrary.simpleMessage(""),
    "sleepTimerStart": MessageLookupByLibrary.simpleMessage(""),
    "sleepTimerWait": MessageLookupByLibrary.simpleMessage(""),
    "sleepTimerWaitFor": MessageLookupByLibrary.simpleMessage(""),
    "sortBy": MessageLookupByLibrary.simpleMessage(""),
    "sortOrder": MessageLookupByLibrary.simpleMessage(""),
    "status": MessageLookupByLibrary.simpleMessage("状态"),
    "statusAuthError": MessageLookupByLibrary.simpleMessage("验证错误"),
    "statusFail": MessageLookupByLibrary.simpleMessage("失败"),
    "statusSuccess": MessageLookupByLibrary.simpleMessage("成功"),
    "stop": MessageLookupByLibrary.simpleMessage("停止"),
    "subscribe": MessageLookupByLibrary.simpleMessage("订阅"),
    "subscribeExportDes": MessageLookupByLibrary.simpleMessage("导出 OPML 文件"),
    "subscribed": MessageLookupByLibrary.simpleMessage(""),
    "suggestName": MessageLookupByLibrary.simpleMessage(""),
    "sync": MessageLookupByLibrary.simpleMessage(""),
    "syncFinished": MessageLookupByLibrary.simpleMessage(""),
    "syncNow": MessageLookupByLibrary.simpleMessage("立即同步"),
    "syncStarted": MessageLookupByLibrary.simpleMessage(""),
    "systemDefault": MessageLookupByLibrary.simpleMessage("系统默认"),
    "timeLastPlayed": m32,
    "timeLeft": m33,
    "to": m34,
    "toastAddPlaylist": MessageLookupByLibrary.simpleMessage("添加到播放列表"),
    "toastBackupRestoreFailure": MessageLookupByLibrary.simpleMessage(""),
    "toastBackupRestoreSuccess": MessageLookupByLibrary.simpleMessage(""),
    "toastDiscovery": MessageLookupByLibrary.simpleMessage("重启应用后可查看"),
    "toastFileError": MessageLookupByLibrary.simpleMessage("文件错误，导入失败"),
    "toastFileNotValid": MessageLookupByLibrary.simpleMessage("文件错误"),
    "toastHomeGroupNotSupport": MessageLookupByLibrary.simpleMessage(
      "Home 分组不支持此功能",
    ),
    "toastImportSettingsSuccess": MessageLookupByLibrary.simpleMessage(
      "导入设置成功",
    ),
    "toastOneGroup": MessageLookupByLibrary.simpleMessage("请至少选择一个分组"),
    "toastPodcastRecovering": MessageLookupByLibrary.simpleMessage("恢复中，请稍后"),
    "toastReadFile": MessageLookupByLibrary.simpleMessage("读取文件成功"),
    "toastRecoverFailed": MessageLookupByLibrary.simpleMessage("恢复订阅失败"),
    "toastRemovePlaylist": MessageLookupByLibrary.simpleMessage("从播放列表移除"),
    "toastResetSuccessful": MessageLookupByLibrary.simpleMessage(""),
    "toastRestart": MessageLookupByLibrary.simpleMessage(""),
    "toastSettingSaved": MessageLookupByLibrary.simpleMessage("设置已保存"),
    "toastTimeEqualEnd": MessageLookupByLibrary.simpleMessage("与结束时刻相同"),
    "toastTimeEqualStart": MessageLookupByLibrary.simpleMessage("与起始时刻相同"),
    "translate": MessageLookupByLibrary.simpleMessage(""),
    "translators": MessageLookupByLibrary.simpleMessage("翻译者"),
    "understood": MessageLookupByLibrary.simpleMessage("了解"),
    "undo": MessageLookupByLibrary.simpleMessage("撤销"),
    "unlike": MessageLookupByLibrary.simpleMessage("取消喜欢"),
    "unliked": MessageLookupByLibrary.simpleMessage("从收藏移除"),
    "unsupported": MessageLookupByLibrary.simpleMessage(""),
    "updateDate": MessageLookupByLibrary.simpleMessage("更新日期"),
    "updateEpisodesCount": m35,
    "updateFailed": MessageLookupByLibrary.simpleMessage("更新失败"),
    "username": MessageLookupByLibrary.simpleMessage("用户名"),
    "usernameRequired": MessageLookupByLibrary.simpleMessage("用户名为空"),
    "version": m36,
    "vpn": MessageLookupByLibrary.simpleMessage(""),
    "weeksCount": m37,
    "welcome": MessageLookupByLibrary.simpleMessage(""),
    "wifi": MessageLookupByLibrary.simpleMessage(""),
    "yearsCount": m38,
  };
}
