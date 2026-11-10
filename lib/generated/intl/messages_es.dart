// DO NOT EDIT. This is code generated via package:intl/generate_localized.dart
// This is a library that provides messages for a es locale. All the
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
  String get localeName => 'es';

  static String m0(groupName, count) =>
      "${Intl.plural(count, zero: '', one: '${count} episodio de ${groupName} añadido a la lista', other: '${count} episodios en ${groupName} añadidos a la lista')}";

  static String m1(count) =>
      "${Intl.plural(count, zero: '', one: '${count} episodio añadido a la lista', other: '${count} episodios añadidos a la lista')}";

  static String m2(count) =>
      "${Intl.plural(count, zero: 'Hoy', one: 'Hace ${count} dia', other: 'Hace ${count} dias')}";

  static String m3(count) =>
      "${Intl.plural(count, zero: 'Nunca', one: '${count} dia', other: '${count} dias')}";

  static String m4(count) =>
      "${Intl.plural(count, zero: '', one: 'Episodio', other: 'Episodios')}";

  static String m5(type) => "Filtrar ${type}";

  static String m6(time) => "De ${time}";

  static String m7(icon) => "";

  static String m8(count) =>
      "${Intl.plural(count, zero: 'Grupo', one: 'Grupo', other: 'Grupos')}";

  static String m9(host) => "Alojado en ${host}";

  static String m10(count) =>
      "${Intl.plural(count, zero: 'Justo ahora', one: 'Hace ${count} hora', other: 'Hace ${count} horas')}";

  static String m11(count) =>
      "${Intl.plural(count, zero: 'Cero horas', one: '${count} hora', other: '${count} horas')}";

  static String m12(service) => "Integrar con ${service}";

  static String m13(filePath) => "Episodio local en ${filePath}";

  static String m14(userName) => "Sesión iniciado como ${userName}";

  static String m15(count) =>
      "${Intl.plural(count, zero: 'Justo Ahora', one: 'Hace ${count} minuto ', other: 'Hace ${count} minutos')}";

  static String m16(count) =>
      "${Intl.plural(count, zero: '0 minutos', one: '${count} minuto', other: '${count} minutos')}";

  static String m17(count) => "";

  static String m18(title) => "Obtener datos ${title}";

  static String m19(title) => "Suscripción fallida, error de red ${title}";

  static String m20(title) => "Suscribir ${title}";

  static String m21(title) => "Suscripción fallida, podcast ya existe ${title}";

  static String m22(title) => "Suscripción exitosa";

  static String m23(title) => "Actualizar ${title}";

  static String m24(title) => "Error de actualización ${title}";

  static String m25(count) =>
      "${Intl.plural(count, zero: '', one: 'Podcast', other: 'Podcasts')}";

  static String m26(date) => "Publicado el ${date}";

  static String m27(date) => "Removido el (fecha)";

  static String m28(start, end) => "";

  static String m29(count) =>
      "${Intl.plural(count, zero: '0 segundos', one: '${count} segundo', other: '${count} segundos')}";

  static String m30(count) =>
      "${Intl.plural(count, zero: 'Justo ahora', one: 'Hace ${count} segundo ', other: 'Hace ${count} segundos')}";

  static String m31(count) => "${count} selecciones";

  static String m32(time) => "Tiempo previo ${time}";

  static String m33(time) => "${time} Restante";

  static String m34(time) => "A ${time}";

  static String m35(count) =>
      "${Intl.plural(count, zero: 'No hay actualizaciones', one: 'Se actualizo ${count} episodio', other: 'Se actualizaron ${count} episodios')}";

  static String m36(version) => "Versión: ${version}";

  static String m37(count) => "";

  static String m38(count) => "";

  final messages = _notInlinedMessages(_notInlinedMessages);
  static Map<String, Function> _notInlinedMessages(_) => <String, Function>{
    "aboutDes": MessageLookupByLibrary.simpleMessage(""),
    "add": MessageLookupByLibrary.simpleMessage("Añadir"),
    "addEpisodeGroup": m0,
    "addNewEpisodeAll": m1,
    "addNewEpisodeTooltip": MessageLookupByLibrary.simpleMessage(
      "Añade nuevos episodios a la lista de reproducción",
    ),
    "addSomeGroups": MessageLookupByLibrary.simpleMessage("Añade algún grupo"),
    "after": MessageLookupByLibrary.simpleMessage("Después"),
    "all": MessageLookupByLibrary.simpleMessage("Todos"),
    "apiSearch": MessageLookupByLibrary.simpleMessage(""),
    "autoDownload": MessageLookupByLibrary.simpleMessage("Auto-descargar"),
    "back": MessageLookupByLibrary.simpleMessage("Atras"),
    "before": MessageLookupByLibrary.simpleMessage("Antes"),
    "between": MessageLookupByLibrary.simpleMessage("Entre"),
    "boostVolume": MessageLookupByLibrary.simpleMessage("Aumentar volumen"),
    "buffering": MessageLookupByLibrary.simpleMessage("Cargando "),
    "cancel": MessageLookupByLibrary.simpleMessage("CANCELAR"),
    "capitalDefault": MessageLookupByLibrary.simpleMessage("Por defecto"),
    "cellularConfirm": MessageLookupByLibrary.simpleMessage(
      "Alerta de datos móviles ",
    ),
    "cellularConfirmDes": MessageLookupByLibrary.simpleMessage(
      "¿Seguro que quieres usar datos móviles para realizar descargas?",
    ),
    "changeLayout": MessageLookupByLibrary.simpleMessage("Cambiar diseño"),
    "changelog": MessageLookupByLibrary.simpleMessage("Reporte de cambios"),
    "chooseA": MessageLookupByLibrary.simpleMessage("Escoger un"),
    "clear": MessageLookupByLibrary.simpleMessage("Limpiar"),
    "clearAll": MessageLookupByLibrary.simpleMessage("Limipar todo"),
    "close": MessageLookupByLibrary.simpleMessage("Cerrar"),
    "color": MessageLookupByLibrary.simpleMessage("color"),
    "confirm": MessageLookupByLibrary.simpleMessage("ACEPTAR"),
    "confirmation": MessageLookupByLibrary.simpleMessage(""),
    "contribute": MessageLookupByLibrary.simpleMessage(""),
    "createNewPlaylist": MessageLookupByLibrary.simpleMessage("Nueva playlist"),
    "darkMode": MessageLookupByLibrary.simpleMessage("Modo oscuro"),
    "daysAgo": m2,
    "daysCount": m3,
    "defaultQueueReminder": MessageLookupByLibrary.simpleMessage(
      "Esta es la cola por defecto, no puede removerse",
    ),
    "defaultSearchEngine": MessageLookupByLibrary.simpleMessage(
      "Motor de busqueda de podcasts por defecto",
    ),
    "defaultSearchEngineDes": MessageLookupByLibrary.simpleMessage(
      "Escoge el motor de busqueda de podcasts por defecto ",
    ),
    "delete": MessageLookupByLibrary.simpleMessage("Eliminar"),
    "deleted": MessageLookupByLibrary.simpleMessage(""),
    "deletedEpisodeDesc": MessageLookupByLibrary.simpleMessage(""),
    "deletedPodcastDesc": MessageLookupByLibrary.simpleMessage(""),
    "deselectAll": MessageLookupByLibrary.simpleMessage("Desmarcar Todo"),
    "details": MessageLookupByLibrary.simpleMessage(""),
    "developer": MessageLookupByLibrary.simpleMessage("Desarrollador"),
    "developerOriginal": MessageLookupByLibrary.simpleMessage(""),
    "deviceStorage": MessageLookupByLibrary.simpleMessage(""),
    "disabled": MessageLookupByLibrary.simpleMessage(""),
    "dismiss": MessageLookupByLibrary.simpleMessage("Minimizar"),
    "displayVersion": MessageLookupByLibrary.simpleMessage(""),
    "done": MessageLookupByLibrary.simpleMessage("Hecho"),
    "download": MessageLookupByLibrary.simpleMessage("Descargar"),
    "downloadDate": MessageLookupByLibrary.simpleMessage("Fecha de descarga"),
    "downloadRemovedToast": MessageLookupByLibrary.simpleMessage(
      "Descarga removida",
    ),
    "downloadStart": MessageLookupByLibrary.simpleMessage("Descargando"),
    "downloaded": MessageLookupByLibrary.simpleMessage("Descargados"),
    "downloading": MessageLookupByLibrary.simpleMessage(""),
    "duration": MessageLookupByLibrary.simpleMessage("Duración"),
    "editGroupName": MessageLookupByLibrary.simpleMessage(
      "Editar nombre del grupo",
    ),
    "endOfEpisode": MessageLookupByLibrary.simpleMessage("Fin del episodio"),
    "episode": m4,
    "fastForward": MessageLookupByLibrary.simpleMessage("Avanzar"),
    "fastRewind": MessageLookupByLibrary.simpleMessage("Retroceder"),
    "featureDiscoveryEditGroup": MessageLookupByLibrary.simpleMessage(
      "Toca para editar grupo",
    ),
    "featureDiscoveryEditGroupDes": MessageLookupByLibrary.simpleMessage(
      "Puedes cambiar el nombre del grupo o eliminar el grupo aquí, el grupo Home no puede ser editado ni borrado",
    ),
    "featureDiscoveryEpisode": MessageLookupByLibrary.simpleMessage(
      "Vista de episodios",
    ),
    "featureDiscoveryEpisodeDes": MessageLookupByLibrary.simpleMessage(
      "Puedes mantener presionado para reproducir o añadir un episodio a la lista de reproducción ",
    ),
    "featureDiscoveryEpisodeTitle": MessageLookupByLibrary.simpleMessage(
      "Mantén presionado para reproducir episodio instantáneamente",
    ),
    "featureDiscoveryGroup": MessageLookupByLibrary.simpleMessage(
      "Toca para añadir grupo",
    ),
    "featureDiscoveryGroupDes": MessageLookupByLibrary.simpleMessage(
      "El grupo por defecto para nuevos podcasts es Home, puedes crear nuevos grupos y mover podcasts ahí. Puedes poner un podcast en varios grupos",
    ),
    "featureDiscoveryGroupPodcast": MessageLookupByLibrary.simpleMessage(
      "Mantén presionado para re-ordenar podcasts",
    ),
    "featureDiscoveryGroupPodcastDes": MessageLookupByLibrary.simpleMessage(
      "Puedes tocar para ver mas opciones, o mantener presionado para ordenar podcasts en grupos",
    ),
    "featureDiscoveryOMPL": MessageLookupByLibrary.simpleMessage(
      "Toca para importar un OPML",
    ),
    "featureDiscoveryOMPLDes": MessageLookupByLibrary.simpleMessage(
      "Puedes importar archivos OPML, abre los ajustes o refresca todos los podcasts aquí ",
    ),
    "featureDiscoveryPlaylist": MessageLookupByLibrary.simpleMessage(
      "Toca para abrir lista de reproducción ",
    ),
    "featureDiscoveryPlaylistDes": MessageLookupByLibrary.simpleMessage(
      "Puedes añadir episodios a la lista de reproducción. El episodio se removerá automáticamente de la lista una vez reproducido ",
    ),
    "featureDiscoveryPodcast": MessageLookupByLibrary.simpleMessage("Vista"),
    "featureDiscoveryPodcastDes": MessageLookupByLibrary.simpleMessage(
      "Puedes tocar \"Ver Todos\" para añadir grupos u organizar podcasts ",
    ),
    "featureDiscoveryPodcastTitle": MessageLookupByLibrary.simpleMessage(
      "Desplazate verticalmente para cambiar entre grupos",
    ),
    "featureDiscoverySearch": MessageLookupByLibrary.simpleMessage(
      "Toca para buscar podcast",
    ),
    "featureDiscoverySearchDes": MessageLookupByLibrary.simpleMessage(
      "Puedes buscar podcasts, palabras clave o enlaces RSS para añadir nuevos podcasts",
    ),
    "feedbackEmail": MessageLookupByLibrary.simpleMessage("Escríbeme "),
    "feedbackGithub": MessageLookupByLibrary.simpleMessage("Reportar problema"),
    "feedbackPlay": MessageLookupByLibrary.simpleMessage(
      "Calificar en Play Store",
    ),
    "feedbackTelegram": MessageLookupByLibrary.simpleMessage("Unirse a grupo"),
    "filter": MessageLookupByLibrary.simpleMessage("Filtrar"),
    "filterType": m5,
    "fontStyle": MessageLookupByLibrary.simpleMessage("Estilo de fuente"),
    "fonts": MessageLookupByLibrary.simpleMessage("Tipografías"),
    "forward": MessageLookupByLibrary.simpleMessage(""),
    "from": m6,
    "getStarted": MessageLookupByLibrary.simpleMessage(""),
    "getStartedDes": m7,
    "globallyDisabled": MessageLookupByLibrary.simpleMessage(""),
    "goodNight": MessageLookupByLibrary.simpleMessage("Buenas noches"),
    "gpodderLoginDes": MessageLookupByLibrary.simpleMessage(
      "Felicidades, has unido tu cuenta gpodder.net exitosamente. Tsacdop sincronizara tus subscripciones en tu dispositivo con tu cuenta gpodder.net.",
    ),
    "groupExisted": MessageLookupByLibrary.simpleMessage("El grupo ya existe"),
    "groupRemoveConfirm": MessageLookupByLibrary.simpleMessage(
      "¿Estas seguro de que quieres remover este grupo? Los podcasts serán movidos al grupo Home",
    ),
    "groups": m8,
    "haptics": MessageLookupByLibrary.simpleMessage(""),
    "hapticsDes": MessageLookupByLibrary.simpleMessage(""),
    "hideListenedSetting": MessageLookupByLibrary.simpleMessage(
      "Ocultar escuchados",
    ),
    "hidePodcastDiscovery": MessageLookupByLibrary.simpleMessage(
      "Ocultar descubrimiento de podcasts",
    ),
    "hidePodcastDiscoveryDes": MessageLookupByLibrary.simpleMessage(
      "Ocultar descubrimiento de pocasts en el motor de busqueda",
    ),
    "homeGroupsSeeAll": MessageLookupByLibrary.simpleMessage("Ver todo"),
    "homeMenuPlaylist": MessageLookupByLibrary.simpleMessage(
      "Lista de reproducción",
    ),
    "homeSubMenuSortBy": MessageLookupByLibrary.simpleMessage("Ordenar por"),
    "homeTabMenuFavotite": MessageLookupByLibrary.simpleMessage("Favoritos"),
    "homeTabMenuRecent": MessageLookupByLibrary.simpleMessage("Recientes"),
    "homeToprightMenuAbout": MessageLookupByLibrary.simpleMessage("Acerca de"),
    "homeToprightMenuImportOMPL": MessageLookupByLibrary.simpleMessage(
      "Importar OPML",
    ),
    "homeToprightMenuRefreshAll": MessageLookupByLibrary.simpleMessage(
      "Refrescar todo",
    ),
    "hostedOn": m9,
    "hoursAgo": m10,
    "hoursCount": m11,
    "import": MessageLookupByLibrary.simpleMessage("Importar"),
    "importingOpml": MessageLookupByLibrary.simpleMessage(""),
    "interaction": MessageLookupByLibrary.simpleMessage("Interacción"),
    "intergateWith": m12,
    "introFourthPage": MessageLookupByLibrary.simpleMessage(
      "Puedes mantener presionado un episodio para realizar acciones rápidas",
    ),
    "introSecondPage": MessageLookupByLibrary.simpleMessage(
      "Suscribete a podcasts buscándolos, o importando un archivo OPML",
    ),
    "introThirdPage": MessageLookupByLibrary.simpleMessage(
      "Puedes crear un nuevo grupo de podcasts",
    ),
    "invalidName": MessageLookupByLibrary.simpleMessage(
      "Nombre de usuario invalido",
    ),
    "keepAndroidOpen": MessageLookupByLibrary.simpleMessage(""),
    "keepAndroidOpenDes": MessageLookupByLibrary.simpleMessage(""),
    "lastUpdate": MessageLookupByLibrary.simpleMessage("Ultima actualización"),
    "later": MessageLookupByLibrary.simpleMessage("Despues"),
    "lightMode": MessageLookupByLibrary.simpleMessage("Modo claro"),
    "like": MessageLookupByLibrary.simpleMessage("Me gusta"),
    "likeDate": MessageLookupByLibrary.simpleMessage("Fecha en que Me Gusto"),
    "liked": MessageLookupByLibrary.simpleMessage("Me gusta"),
    "listen": MessageLookupByLibrary.simpleMessage("Escuchar"),
    "listened": MessageLookupByLibrary.simpleMessage("Escuchado"),
    "loadAllSelected": MessageLookupByLibrary.simpleMessage(""),
    "loadMore": MessageLookupByLibrary.simpleMessage("Cargar mas"),
    "loading": MessageLookupByLibrary.simpleMessage("Cargando"),
    "localEpisodeDescription": m13,
    "localFolder": MessageLookupByLibrary.simpleMessage(""),
    "localFolderDescription": MessageLookupByLibrary.simpleMessage(""),
    "localizationWeblate": MessageLookupByLibrary.simpleMessage(""),
    "loggedInAs": m14,
    "login": MessageLookupByLibrary.simpleMessage("Iniciar sesión"),
    "loginFailed": MessageLookupByLibrary.simpleMessage(
      "Inicio de sesión fallido",
    ),
    "logout": MessageLookupByLibrary.simpleMessage("Cerrar sesión"),
    "mark": MessageLookupByLibrary.simpleMessage("Completado"),
    "markConfirm": MessageLookupByLibrary.simpleMessage("Confirmar marcado"),
    "markConfirmContent": MessageLookupByLibrary.simpleMessage(
      "¿Marcar todos los episodios como escuchados?",
    ),
    "markListened": MessageLookupByLibrary.simpleMessage("Marcar escuchados"),
    "markNotListened": MessageLookupByLibrary.simpleMessage(
      "Marcar no escuchados",
    ),
    "menu": MessageLookupByLibrary.simpleMessage("Menú"),
    "menuAllPodcasts": MessageLookupByLibrary.simpleMessage(
      "Todos los podcasts",
    ),
    "menuMarkAllListened": MessageLookupByLibrary.simpleMessage(
      "Marcar todo como escuchado",
    ),
    "menuViewRSS": MessageLookupByLibrary.simpleMessage("Visitar feed RSS"),
    "menuVisitSite": MessageLookupByLibrary.simpleMessage("Visitar sitio web"),
    "minsAgo": m15,
    "minsCount": m16,
    "mobileData": MessageLookupByLibrary.simpleMessage(""),
    "monthsCount": m17,
    "moreOptions": MessageLookupByLibrary.simpleMessage("Más Opciones"),
    "network": MessageLookupByLibrary.simpleMessage("Red"),
    "networkErrorDNS": MessageLookupByLibrary.simpleMessage(
      "Error de red (problema de DNS)",
    ),
    "neverAutoUpdate": MessageLookupByLibrary.simpleMessage(
      "Desactivar actualizaciones automaticas ",
    ),
    "neverAutoUpdateDes": MessageLookupByLibrary.simpleMessage(""),
    "newGroup": MessageLookupByLibrary.simpleMessage("Crear grupo nuevo"),
    "newPlain": MessageLookupByLibrary.simpleMessage("Nuevo"),
    "newPlaylist": MessageLookupByLibrary.simpleMessage(""),
    "newestFirst": MessageLookupByLibrary.simpleMessage(
      "Mas recientes primero",
    ),
    "next": MessageLookupByLibrary.simpleMessage("Siguiente"),
    "noEpisodesFound": MessageLookupByLibrary.simpleMessage(""),
    "noPodcastGroup": MessageLookupByLibrary.simpleMessage(
      "No hay podcasts en este grupo",
    ),
    "noShownote": MessageLookupByLibrary.simpleMessage(
      "Aun no hay notas disponibles para este episodio",
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
    "oldestFirst": MessageLookupByLibrary.simpleMessage("Mas antiguos primero"),
    "opmlFile": MessageLookupByLibrary.simpleMessage(""),
    "passwdRequired": MessageLookupByLibrary.simpleMessage(
      "Contraseña requerida",
    ),
    "password": MessageLookupByLibrary.simpleMessage("Contraseña"),
    "pause": MessageLookupByLibrary.simpleMessage("Pausa"),
    "play": MessageLookupByLibrary.simpleMessage("Reproducir"),
    "playNext": MessageLookupByLibrary.simpleMessage("Reproducir siguiente"),
    "playNextDes": MessageLookupByLibrary.simpleMessage(
      "Añadir episodio a la cima de la playlist",
    ),
    "playback": MessageLookupByLibrary.simpleMessage("Control de reproducción"),
    "player": MessageLookupByLibrary.simpleMessage("Reproductor"),
    "playerHeightMed": MessageLookupByLibrary.simpleMessage("Medio"),
    "playerHeightShort": MessageLookupByLibrary.simpleMessage("Bajo"),
    "playerHeightTall": MessageLookupByLibrary.simpleMessage("Alto"),
    "playing": MessageLookupByLibrary.simpleMessage("Reproduciendo"),
    "playlistExists": MessageLookupByLibrary.simpleMessage(""),
    "playlistNameEmpty": MessageLookupByLibrary.simpleMessage(
      "La playlist no tiene nombre",
    ),
    "playlists": MessageLookupByLibrary.simpleMessage("Playlists"),
    "plugins": MessageLookupByLibrary.simpleMessage("Plugins"),
    "podcast": m25,
    "podcastList": MessageLookupByLibrary.simpleMessage(""),
    "podcastSubscribed": MessageLookupByLibrary.simpleMessage(
      "Podcast añadido",
    ),
    "popupMenuDownloadDes": MessageLookupByLibrary.simpleMessage(
      "Descargar episodio",
    ),
    "popupMenuLaterDes": MessageLookupByLibrary.simpleMessage(
      "Añadir episodio a lista de reproducción",
    ),
    "popupMenuLikeDes": MessageLookupByLibrary.simpleMessage(
      "Añadir episodio a favoritos",
    ),
    "popupMenuMarkDes": MessageLookupByLibrary.simpleMessage(
      "Marcar episodio como escuchado",
    ),
    "popupMenuPlayDes": MessageLookupByLibrary.simpleMessage(
      "Reproducir episodio\n",
    ),
    "privacyPolicy": MessageLookupByLibrary.simpleMessage(
      "Política de privacidad",
    ),
    "publishDate": MessageLookupByLibrary.simpleMessage("Fecha de publicación"),
    "published": m26,
    "publishedDaily": MessageLookupByLibrary.simpleMessage(
      "Publicado diariamente",
    ),
    "publishedMonthly": MessageLookupByLibrary.simpleMessage(
      "Publicado mensualmente",
    ),
    "publishedWeekly": MessageLookupByLibrary.simpleMessage(
      "Publicado semanalmente",
    ),
    "publishedYearly": MessageLookupByLibrary.simpleMessage(
      "Publicado anualmente",
    ),
    "queue": MessageLookupByLibrary.simpleMessage("Cola"),
    "random": MessageLookupByLibrary.simpleMessage("Aleatorio"),
    "recoverSubscribe": MessageLookupByLibrary.simpleMessage(
      "Recuperar suscripcion",
    ),
    "refresh": MessageLookupByLibrary.simpleMessage("Refrescar"),
    "refreshArtwork": MessageLookupByLibrary.simpleMessage(
      "Actualizar portada",
    ),
    "remove": MessageLookupByLibrary.simpleMessage("Remover"),
    "removeConfirm": MessageLookupByLibrary.simpleMessage(
      "Confirma la remoción ",
    ),
    "removeDownload": MessageLookupByLibrary.simpleMessage("Eliminar Descarga"),
    "removeNewMark": MessageLookupByLibrary.simpleMessage("Remover marca"),
    "removePodcastDes": MessageLookupByLibrary.simpleMessage(
      "¿Estas seguro de que deseas desuscribirte?",
    ),
    "removedAt": m27,
    "restartAppForEffect": MessageLookupByLibrary.simpleMessage(
      "Reinicie la aplicación para que los cambios surtan efecto.",
    ),
    "satellite": MessageLookupByLibrary.simpleMessage(""),
    "save": MessageLookupByLibrary.simpleMessage("Guardar"),
    "schedule": MessageLookupByLibrary.simpleMessage("Horario"),
    "scheduleDisabled": MessageLookupByLibrary.simpleMessage(""),
    "scheduleTime": m28,
    "search": MessageLookupByLibrary.simpleMessage("Buscar"),
    "searchApi": MessageLookupByLibrary.simpleMessage(""),
    "searchEngine": MessageLookupByLibrary.simpleMessage(""),
    "searchEpisode": MessageLookupByLibrary.simpleMessage("Buscar episodio"),
    "searchHelper": MessageLookupByLibrary.simpleMessage(
      "Escribe el nombre del podcast, palabras clave o un feed url",
    ),
    "searchInstructions": MessageLookupByLibrary.simpleMessage(
      "Introduce la url de un feed rss o busca un podcast y abre su feed rss para suscribirte.",
    ),
    "searchInvalidRss": MessageLookupByLibrary.simpleMessage(
      "Enlace RSS invalido ",
    ),
    "searchPodcast": MessageLookupByLibrary.simpleMessage("Buscar podcast"),
    "searchWeb": MessageLookupByLibrary.simpleMessage(""),
    "secCount": m29,
    "secondsAgo": m30,
    "selectMode": MessageLookupByLibrary.simpleMessage("Modo de Selección"),
    "selected": m31,
    "settingStorage": MessageLookupByLibrary.simpleMessage("Almacenamiento"),
    "settings": MessageLookupByLibrary.simpleMessage("Ajustes"),
    "settingsAccentColor": MessageLookupByLibrary.simpleMessage(
      "Color de acento ",
    ),
    "settingsAppIntro": MessageLookupByLibrary.simpleMessage("Intro de App"),
    "settingsAppearance": MessageLookupByLibrary.simpleMessage("Apariencia"),
    "settingsAppearanceDes": MessageLookupByLibrary.simpleMessage(
      "Tema y Colores\n",
    ),
    "settingsAudioCache": MessageLookupByLibrary.simpleMessage(
      "Cache de audio",
    ),
    "settingsAudioCacheDes": MessageLookupByLibrary.simpleMessage(
      "Tamaño máximo del cache de audio",
    ),
    "settingsAutoDelete": MessageLookupByLibrary.simpleMessage(
      "Auto-eliminar descargas después",
    ),
    "settingsAutoDeleteAfterPlayed": MessageLookupByLibrary.simpleMessage(""),
    "settingsAutoDeleteAfterTime": MessageLookupByLibrary.simpleMessage(""),
    "settingsAutoDeleteAfterTimeDes": MessageLookupByLibrary.simpleMessage(""),
    "settingsAutoDeleteDes": MessageLookupByLibrary.simpleMessage(
      "30 días por defecto",
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
      "Reproducir automaticamente episodio siguiente ",
    ),
    "settingsAutoSync": MessageLookupByLibrary.simpleMessage(""),
    "settingsAutoSyncDes": MessageLookupByLibrary.simpleMessage(""),
    "settingsBackup": MessageLookupByLibrary.simpleMessage("Respaldo"),
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
      "Respaldar datos de la app",
    ),
    "settingsBackupFile": MessageLookupByLibrary.simpleMessage(""),
    "settingsBackupLegacyFile": MessageLookupByLibrary.simpleMessage(""),
    "settingsBackupLegacyFileDes": MessageLookupByLibrary.simpleMessage(""),
    "settingsBackupPassword": MessageLookupByLibrary.simpleMessage(""),
    "settingsBackupPasswordDes": MessageLookupByLibrary.simpleMessage(""),
    "settingsBoostVolume": MessageLookupByLibrary.simpleMessage(
      "Nivel de aumento de volumen",
    ),
    "settingsBoostVolumeDes": MessageLookupByLibrary.simpleMessage(
      "Cambiar nivel de aumento de volumen",
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
      "Vista de cuadricula por defecto",
    ),
    "settingsDefaultGridDownload": MessageLookupByLibrary.simpleMessage(
      "Pestaña de descargas",
    ),
    "settingsDefaultGridFavorite": MessageLookupByLibrary.simpleMessage(
      "Pestaña de favoritos",
    ),
    "settingsDefaultGridPodcast": MessageLookupByLibrary.simpleMessage(
      "Pagina de podcasts",
    ),
    "settingsDefaultGridRecent": MessageLookupByLibrary.simpleMessage(
      "Pestaña de recientes",
    ),
    "settingsDiscovery": MessageLookupByLibrary.simpleMessage(
      "Reiniciar tutorial",
    ),
    "settingsDiscoveryDes": MessageLookupByLibrary.simpleMessage(
      "¿Estás seguro de que quiere reactivar \"Descubrir Características\"?",
    ),
    "settingsDownloadAskOnForbidden": MessageLookupByLibrary.simpleMessage(""),
    "settingsDownloadAskOnForbiddenDes": MessageLookupByLibrary.simpleMessage(
      "",
    ),
    "settingsDownloadPosition": MessageLookupByLibrary.simpleMessage(
      "Posicion de descarga",
    ),
    "settingsDownloads": MessageLookupByLibrary.simpleMessage(""),
    "settingsDownloadsDes": MessageLookupByLibrary.simpleMessage(""),
    "settingsEpisodeManagement": MessageLookupByLibrary.simpleMessage(""),
    "settingsExportDes": MessageLookupByLibrary.simpleMessage(
      "Exportar e importar ajustes de la app",
    ),
    "settingsFastForwardSec": MessageLookupByLibrary.simpleMessage(
      "Segundos de avance",
    ),
    "settingsFastForwardSecDes": MessageLookupByLibrary.simpleMessage(
      "Cambia los segundos de avance del reproductor",
    ),
    "settingsFeedback": MessageLookupByLibrary.simpleMessage("Comentarios"),
    "settingsFeedbackDes": MessageLookupByLibrary.simpleMessage(
      "Haz sugerencias y reporta errores",
    ),
    "settingsForbiddenDownloadConnections":
        MessageLookupByLibrary.simpleMessage(""),
    "settingsForbiddenDownloadConnectionsDes":
        MessageLookupByLibrary.simpleMessage(""),
    "settingsFullStop": MessageLookupByLibrary.simpleMessage(""),
    "settingsFullStopDes": MessageLookupByLibrary.simpleMessage(""),
    "settingsGeneral": MessageLookupByLibrary.simpleMessage(""),
    "settingsHistory": MessageLookupByLibrary.simpleMessage("Historial"),
    "settingsHistoryDes": MessageLookupByLibrary.simpleMessage(
      "Datos de escucha",
    ),
    "settingsHomeTabAdd": MessageLookupByLibrary.simpleMessage(""),
    "settingsHomeTabName": MessageLookupByLibrary.simpleMessage(""),
    "settingsHomeTabNew": MessageLookupByLibrary.simpleMessage(""),
    "settingsHomeTabs": MessageLookupByLibrary.simpleMessage(""),
    "settingsInfo": MessageLookupByLibrary.simpleMessage("Información"),
    "settingsInterface": MessageLookupByLibrary.simpleMessage("Interfaz"),
    "settingsInterfaceDes": MessageLookupByLibrary.simpleMessage(""),
    "settingsLanguage": MessageLookupByLibrary.simpleMessage(""),
    "settingsLegacy": MessageLookupByLibrary.simpleMessage(""),
    "settingsLibraries": MessageLookupByLibrary.simpleMessage("Librerías"),
    "settingsLibrariesDes": MessageLookupByLibrary.simpleMessage(
      "Librerías de código abierto usadas en la app",
    ),
    "settingsLookAndFeel": MessageLookupByLibrary.simpleMessage(""),
    "settingsLookAndFeelDes": MessageLookupByLibrary.simpleMessage(""),
    "settingsManageDownload": MessageLookupByLibrary.simpleMessage(
      "Administrar descargas",
    ),
    "settingsManageDownloadDes": MessageLookupByLibrary.simpleMessage(
      "Administrar archivos de audio descargados",
    ),
    "settingsManufacturerNotificationLayout":
        MessageLookupByLibrary.simpleMessage(""),
    "settingsMarkListenedSkip": MessageLookupByLibrary.simpleMessage(
      "Marcar como escuchado al saltar episodio",
    ),
    "settingsMarkListenedSkipDes": MessageLookupByLibrary.simpleMessage(
      "Marcar episodio como escuchado automaticamente al saltar al siguiente",
    ),
    "settingsMediaControls": MessageLookupByLibrary.simpleMessage(""),
    "settingsMediaControlsDes": MessageLookupByLibrary.simpleMessage(""),
    "settingsMenuAutoPlay": MessageLookupByLibrary.simpleMessage(
      "Auto reproducir siguiente ",
    ),
    "settingsNetworkCellular": MessageLookupByLibrary.simpleMessage(
      "Preguntar antes de usar datos móviles ",
    ),
    "settingsNetworkCellularDes": MessageLookupByLibrary.simpleMessage(
      "Pregunta para confirmar el uso de datos móviles al descargar episodios",
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
      "Menú emergente de episodios ",
    ),
    "settingsPopupMenuDes": MessageLookupByLibrary.simpleMessage(
      "Cambia el menu emergente del episodio",
    ),
    "settingsPrefrence": MessageLookupByLibrary.simpleMessage("Preferencias"),
    "settingsRequirements": MessageLookupByLibrary.simpleMessage(""),
    "settingsRequirementsAll": MessageLookupByLibrary.simpleMessage(""),
    "settingsRequirementsAny": MessageLookupByLibrary.simpleMessage(""),
    "settingsRequirementsDes": MessageLookupByLibrary.simpleMessage(""),
    "settingsReset": MessageLookupByLibrary.simpleMessage(""),
    "settingsRewindSec": MessageLookupByLibrary.simpleMessage(
      "Segundos de retraso",
    ),
    "settingsRewindSecDes": MessageLookupByLibrary.simpleMessage(
      "Cambia los segundos de retroceso del reproductor",
    ),
    "settingsSTAuto": MessageLookupByLibrary.simpleMessage(
      "Encender temporizador de sueño automáticamente",
    ),
    "settingsSTAutoDes": MessageLookupByLibrary.simpleMessage(
      "Encender temporizador de sueño en un horario determinado",
    ),
    "settingsSTDefaultTime": MessageLookupByLibrary.simpleMessage(
      "Tiempo predeterminado",
    ),
    "settingsSTDefautTimeDes": MessageLookupByLibrary.simpleMessage(
      "Tiempo predeterminado de temporizador de sueño",
    ),
    "settingsSTMode": MessageLookupByLibrary.simpleMessage(
      "Modo automático de tempo. de sueño",
    ),
    "settingsSTWaitEpisodeEnd": MessageLookupByLibrary.simpleMessage(""),
    "settingsSTWaitEpisodeEndDes": MessageLookupByLibrary.simpleMessage(""),
    "settingsSearchApi": MessageLookupByLibrary.simpleMessage(""),
    "settingsSearchEngine": MessageLookupByLibrary.simpleMessage(""),
    "settingsSearchMode": MessageLookupByLibrary.simpleMessage(""),
    "settingsSpeeds": MessageLookupByLibrary.simpleMessage("Velocidades"),
    "settingsSpeedsDes": MessageLookupByLibrary.simpleMessage(
      "Personalizar velocidades disponibles",
    ),
    "settingsSyncing": MessageLookupByLibrary.simpleMessage("Sincronización"),
    "settingsSyncingDes": MessageLookupByLibrary.simpleMessage(
      "Actualizar podcasts en el fondo",
    ),
    "settingsSyncingInterval": MessageLookupByLibrary.simpleMessage(""),
    "settingsTapToOpenPopupMenu": MessageLookupByLibrary.simpleMessage(
      "Presiona para abrir el menu",
    ),
    "settingsTapToOpenPopupMenuDes": MessageLookupByLibrary.simpleMessage(
      "Necesitas mantener presionado para abrir la pagina del episodio",
    ),
    "settingsTheme": MessageLookupByLibrary.simpleMessage("Tema"),
    "settingsTrueBlack": MessageLookupByLibrary.simpleMessage(""),
    "settingsTrueBlackDes": MessageLookupByLibrary.simpleMessage(""),
    "settingsUseSystemAccentColor": MessageLookupByLibrary.simpleMessage(""),
    "share": MessageLookupByLibrary.simpleMessage("Compartir"),
    "showNotesFonts": MessageLookupByLibrary.simpleMessage(
      "Fuente de las notas del show",
    ),
    "size": MessageLookupByLibrary.simpleMessage("Tamaño"),
    "skipSecondsAtEnd": MessageLookupByLibrary.simpleMessage(
      "Saltar segundos al final",
    ),
    "skipSecondsAtStart": MessageLookupByLibrary.simpleMessage(
      "Saltar segundos al inicio",
    ),
    "skipSilence": MessageLookupByLibrary.simpleMessage("Saltar silencios"),
    "skipToNext": MessageLookupByLibrary.simpleMessage("Saltar a la siguiente"),
    "skipToPrevious": MessageLookupByLibrary.simpleMessage(""),
    "sleepTimer": MessageLookupByLibrary.simpleMessage("Temporizador de sueño"),
    "sleepTimerCancel": MessageLookupByLibrary.simpleMessage(""),
    "sleepTimerExpireAt": MessageLookupByLibrary.simpleMessage(""),
    "sleepTimerStart": MessageLookupByLibrary.simpleMessage(""),
    "sleepTimerWait": MessageLookupByLibrary.simpleMessage(""),
    "sleepTimerWaitFor": MessageLookupByLibrary.simpleMessage(""),
    "sortBy": MessageLookupByLibrary.simpleMessage("Ordenar Por"),
    "sortOrder": MessageLookupByLibrary.simpleMessage(""),
    "status": MessageLookupByLibrary.simpleMessage("Estatus"),
    "statusAuthError": MessageLookupByLibrary.simpleMessage(
      " Error de autenticación",
    ),
    "statusFail": MessageLookupByLibrary.simpleMessage("Fallido"),
    "statusSuccess": MessageLookupByLibrary.simpleMessage("Exitoso"),
    "stop": MessageLookupByLibrary.simpleMessage("Detener"),
    "subscribe": MessageLookupByLibrary.simpleMessage("Suscribir"),
    "subscribeExportDes": MessageLookupByLibrary.simpleMessage(
      "Exportar OPML de todos los podcasts",
    ),
    "subscribed": MessageLookupByLibrary.simpleMessage(""),
    "suggestName": MessageLookupByLibrary.simpleMessage(""),
    "sync": MessageLookupByLibrary.simpleMessage(""),
    "syncFinished": MessageLookupByLibrary.simpleMessage(""),
    "syncNow": MessageLookupByLibrary.simpleMessage("Sincronizar ahora"),
    "syncStarted": MessageLookupByLibrary.simpleMessage(""),
    "systemDefault": MessageLookupByLibrary.simpleMessage("Acorde al sistema"),
    "timeLastPlayed": m32,
    "timeLeft": m33,
    "to": m34,
    "toastAddPlaylist": MessageLookupByLibrary.simpleMessage(
      "Añadido a la lista de reproducción ",
    ),
    "toastBackupRestoreFailure": MessageLookupByLibrary.simpleMessage(""),
    "toastBackupRestoreSuccess": MessageLookupByLibrary.simpleMessage(""),
    "toastDiscovery": MessageLookupByLibrary.simpleMessage(
      "El tutorial se ha reiniciado, reinicia la app porfavor",
    ),
    "toastFileError": MessageLookupByLibrary.simpleMessage(
      "Error de archivo, suscripción fallida",
    ),
    "toastFileNotValid": MessageLookupByLibrary.simpleMessage(
      "Archivo invalido",
    ),
    "toastHomeGroupNotSupport": MessageLookupByLibrary.simpleMessage(
      "El grupo Home no esta soportado",
    ),
    "toastImportSettingsSuccess": MessageLookupByLibrary.simpleMessage(
      "Ajustes importados correctamente",
    ),
    "toastOneGroup": MessageLookupByLibrary.simpleMessage(
      "Selecciona al menos un grupo",
    ),
    "toastPodcastRecovering": MessageLookupByLibrary.simpleMessage(
      "Recuperando, espera un momento",
    ),
    "toastReadFile": MessageLookupByLibrary.simpleMessage(
      "Archivo leído con exito",
    ),
    "toastRecoverFailed": MessageLookupByLibrary.simpleMessage(
      "Recuperación de podcast fallida",
    ),
    "toastRemovePlaylist": MessageLookupByLibrary.simpleMessage(
      "Episodio removido de la lista de reproducción",
    ),
    "toastResetSuccessful": MessageLookupByLibrary.simpleMessage(""),
    "toastRestart": MessageLookupByLibrary.simpleMessage(""),
    "toastSettingSaved": MessageLookupByLibrary.simpleMessage(
      "Ajustes guardados",
    ),
    "toastTimeEqualEnd": MessageLookupByLibrary.simpleMessage(
      "El tiempo es igual al tiempo final",
    ),
    "toastTimeEqualStart": MessageLookupByLibrary.simpleMessage(
      "El tiempo es igual al tiempo de inicio",
    ),
    "translate": MessageLookupByLibrary.simpleMessage(""),
    "translators": MessageLookupByLibrary.simpleMessage("Traductores"),
    "understood": MessageLookupByLibrary.simpleMessage("Entendido"),
    "undo": MessageLookupByLibrary.simpleMessage("Deshacer "),
    "unlike": MessageLookupByLibrary.simpleMessage("No me gusta"),
    "unliked": MessageLookupByLibrary.simpleMessage(
      "Episodio removido de favoritos",
    ),
    "unsupported": MessageLookupByLibrary.simpleMessage(""),
    "updateDate": MessageLookupByLibrary.simpleMessage(
      "Fecha de actualización ",
    ),
    "updateEpisodesCount": m35,
    "updateFailed": MessageLookupByLibrary.simpleMessage(
      "Actualización fallida, error de red",
    ),
    "username": MessageLookupByLibrary.simpleMessage("Nombre de usuario"),
    "usernameRequired": MessageLookupByLibrary.simpleMessage(
      "Nombre de usuario requerido",
    ),
    "version": m36,
    "vpn": MessageLookupByLibrary.simpleMessage(""),
    "weeksCount": m37,
    "welcome": MessageLookupByLibrary.simpleMessage(""),
    "wifi": MessageLookupByLibrary.simpleMessage(""),
    "yearsCount": m38,
  };
}
