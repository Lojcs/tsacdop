// DO NOT EDIT. This is code generated via package:intl/generate_localized.dart
// This is a library that provides messages for a pt locale. All the
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
  String get localeName => 'pt';

  static String m2(groupName, count) =>
      "${Intl.plural(count, zero: '', one: '${count} episódio de ${groupName} adicionado à lista', other: '${count} episódios de ${groupName} adicionados à lista')}";

  static String m3(count) =>
      "${Intl.plural(count, zero: '', one: '${count} episódio adicionado à lista', other: '${count} episódios adicionados à lista')}";

  static String m4(count) =>
      "${Intl.plural(count, zero: 'Hoje', one: 'Há ${count} dia', other: 'Há ${count} dias')}";

  static String m5(count) =>
      "${Intl.plural(count, zero: 'Nunca', one: '${count} dia', other: '${count} dias')}";

  static String m6(count) =>
      "${Intl.plural(count, zero: '', one: 'Episódio', other: 'Episódios')}";

  static String m32(type) => "Filtro: ${type}";

  static String m7(time) => "De ${time}";

  static String m8(count) =>
      "${Intl.plural(count, zero: 'Grupo', one: 'Grupo', other: 'Grupos')}";

  static String m0(host) => "Alojado em ${host}";

  static String m9(count) =>
      "${Intl.plural(count, zero: 'Nesta hora', one: 'Há ${count} hora', other: 'Há ${count} horas')}";

  static String m10(count) =>
      "${Intl.plural(count, zero: '0 horas', one: '${count} hora', other: '${count} horas')}";

  static String m11(service) => "Integrar com ${service}";

  static String m34(filePath) => "Episódio local em ${filePath}";

  static String m1(userName) => "Iniciou sessão como ${userName}";

  static String m12(count) =>
      "${Intl.plural(count, zero: 'Agora', one: 'Há ${count} minuto', other: 'Há ${count} minutos')}";

  static String m13(count) =>
      "${Intl.plural(count, zero: '0 minutos', one: '${count} minuto', other: '${count} minutos')}";

  static String m14(title) => "Obter dados de ${title}";

  static String m15(title) => "Falha ao subscrever, erro de rede ${title}";

  static String m16(title) => "Subscrever ${title}";

  static String m17(title) => "Falha ao subscrever, podcast já existe ${title}";

  static String m18(title) => "${title} subscrito com sucesso";

  static String m19(title) => "Atualizar ${title}";

  static String m20(title) => "Erro ao atualizar ${title}";

  static String m21(count) =>
      "${Intl.plural(count, zero: '', one: 'Podcast', other: 'Podcasts')}";

  static String m22(date) => "Publicado em ${date}";

  static String m23(date) => "Removido em ${date}";

  static String m24(count) =>
      "${Intl.plural(count, zero: '0 segundos', one: '${count} segundo', other: '${count} segundos')}";

  static String m25(count) =>
      "${Intl.plural(count, zero: 'Agora mesmo', one: 'Há ${count} segundo', other: 'Há ${count} segundos')}";

  static String m26(count) => "${count} selecionado(s)";

  static String m27(time) => "Última posição ${time}";

  static String m28(time) => "${time} restante";

  static String m29(time) => "Para ${time}";

  static String m30(count) =>
      "${Intl.plural(count, zero: 'Sem atualizações', one: '${count} episódio atualizado', other: '${count} episódios atualizados')}";

  static String m31(version) => "Versão: ${version}";

  final messages = _notInlinedMessages(_notInlinedMessages);
  static Map<String, Function> _notInlinedMessages(_) => <String, Function>{
        "add": MessageLookupByLibrary.simpleMessage("Adicionar"),
        "addEpisodeGroup": m2,
        "addNewEpisodeAll": m3,
        "addNewEpisodeTooltip": MessageLookupByLibrary.simpleMessage(
            "Adicionar novos episódios à lista de reprodução"),
        "addSomeGroups":
            MessageLookupByLibrary.simpleMessage("Adicionar grupos"),
        "after": MessageLookupByLibrary.simpleMessage("Após"),
        "all": MessageLookupByLibrary.simpleMessage("Todos"),
        "apiSearch": MessageLookupByLibrary.simpleMessage("API de pesquisa"),
        "autoDownload":
            MessageLookupByLibrary.simpleMessage("Descarga automática"),
        "back": MessageLookupByLibrary.simpleMessage("Recuar"),
        "before": MessageLookupByLibrary.simpleMessage("Antes"),
        "between": MessageLookupByLibrary.simpleMessage("Entre"),
        "boostVolume": MessageLookupByLibrary.simpleMessage("Aumentar volume"),
        "buffering": MessageLookupByLibrary.simpleMessage("A processar"),
        "cancel": MessageLookupByLibrary.simpleMessage("Cancelar"),
        "capitalDefault": MessageLookupByLibrary.simpleMessage("Padrão"),
        "cellularConfirm":
            MessageLookupByLibrary.simpleMessage("Aviso de dados móveis"),
        "cellularConfirmDes": MessageLookupByLibrary.simpleMessage(
            "Tem a certeza de que deseja descarregar ficheiros através de dados móveis?"),
        "changeLayout": MessageLookupByLibrary.simpleMessage("Mudar esquema"),
        "changelog": MessageLookupByLibrary.simpleMessage("Alterações"),
        "chooseA": MessageLookupByLibrary.simpleMessage("Escolher"),
        "clear": MessageLookupByLibrary.simpleMessage("Limpar"),
        "clearAll": MessageLookupByLibrary.simpleMessage("Limpar tudo"),
        "close": MessageLookupByLibrary.simpleMessage("Fechar"),
        "color": MessageLookupByLibrary.simpleMessage("cor"),
        "confirm": MessageLookupByLibrary.simpleMessage("Confirmação"),
        "createNewPlaylist":
            MessageLookupByLibrary.simpleMessage("Nova lista de reprodução"),
        "darkMode": MessageLookupByLibrary.simpleMessage("Modo escuro"),
        "daysAgo": m4,
        "daysCount": m5,
        "defaultQueueReminder": MessageLookupByLibrary.simpleMessage(
            "Esta é a fila padrão e não pode ser removida."),
        "defaultSearchEngine": MessageLookupByLibrary.simpleMessage(
            "Mecanismo padrão de pesquisa"),
        "defaultSearchEngineDes": MessageLookupByLibrary.simpleMessage(
            "Escolha o mecanismo padrão e pesquisa"),
        "delete": MessageLookupByLibrary.simpleMessage("Eliminar"),
        "deleted": MessageLookupByLibrary.simpleMessage("Eliminado"),
        "deletedEpisodeDesc": MessageLookupByLibrary.simpleMessage(
            "Este episódio foi removido da base de dados"),
        "deletedPodcastDesc": MessageLookupByLibrary.simpleMessage(
            "Este podcast foi removido da base de dados"),
        "deselectAll": MessageLookupByLibrary.simpleMessage("Desmarcar tudo"),
        "details": MessageLookupByLibrary.simpleMessage("Detalhes"),
        "developer": MessageLookupByLibrary.simpleMessage("Programador"),
        "deviceStorage":
            MessageLookupByLibrary.simpleMessage("Armazenamento interno"),
        "dismiss": MessageLookupByLibrary.simpleMessage("Descartar"),
        "displayVersion":
            MessageLookupByLibrary.simpleMessage("Versão exibida"),
        "done": MessageLookupByLibrary.simpleMessage("Feito"),
        "download": MessageLookupByLibrary.simpleMessage("Descarregar"),
        "downloadDate":
            MessageLookupByLibrary.simpleMessage("Data de descarga"),
        "downloadRemovedToast":
            MessageLookupByLibrary.simpleMessage("Descarga removida"),
        "downloadStart": MessageLookupByLibrary.simpleMessage("A descarregar"),
        "downloaded": MessageLookupByLibrary.simpleMessage("Descarregado"),
        "downloading": MessageLookupByLibrary.simpleMessage("A descarregar"),
        "duration": MessageLookupByLibrary.simpleMessage("Duração"),
        "editGroupName":
            MessageLookupByLibrary.simpleMessage("Editar nome do grupo"),
        "endOfEpisode": MessageLookupByLibrary.simpleMessage("Fim do episódio"),
        "episode": m6,
        "fastForward": MessageLookupByLibrary.simpleMessage("Avanço rápido"),
        "fastRewind": MessageLookupByLibrary.simpleMessage("Recuo rápido"),
        "featureDiscoveryEditGroup":
            MessageLookupByLibrary.simpleMessage("Toque para editar o grupo"),
        "featureDiscoveryEditGroupDes": MessageLookupByLibrary.simpleMessage(
            "Pode alterar o nome do grupo ou apagar aqui, mas o grupo Home não pode ser editado ou eliminado"),
        "featureDiscoveryEpisode":
            MessageLookupByLibrary.simpleMessage("Vista de episódios"),
        "featureDiscoveryEpisodeDes": MessageLookupByLibrary.simpleMessage(
            "Toque longo para reproduzir um episódio ou adicionar a uma lista de reprodução."),
        "featureDiscoveryEpisodeTitle": MessageLookupByLibrary.simpleMessage(
            "Toque longo para reproduzir um episódio"),
        "featureDiscoveryGroup": MessageLookupByLibrary.simpleMessage(
            "Toque para adicionar um grupo"),
        "featureDiscoveryGroupDes": MessageLookupByLibrary.simpleMessage(
            "O grupo Home é o padrão para novos podcasts. Pode criar novos grupos e mover os podcasts entre grupos, assim como adicionar podcasts a vários grupos."),
        "featureDiscoveryGroupPodcast": MessageLookupByLibrary.simpleMessage(
            "Toque longo para reordenar podcasts"),
        "featureDiscoveryGroupPodcastDes": MessageLookupByLibrary.simpleMessage(
            "Um toque para mais opções ou toque longo para reordenar podcasts em grupos."),
        "featureDiscoveryOMPL":
            MessageLookupByLibrary.simpleMessage("Toque para importar um OPML"),
        "featureDiscoveryOMPLDes": MessageLookupByLibrary.simpleMessage(
            "Pode importar ficheiros OPML, abrir as definições ou atualizar todos os podcasts aqui."),
        "featureDiscoveryPlaylist": MessageLookupByLibrary.simpleMessage(
            "Toque para abrir a lista de reprodução"),
        "featureDiscoveryPlaylistDes": MessageLookupByLibrary.simpleMessage(
            "Pode adicionar episódios às listas de reprodução manualmente. Os episódios serão removidos automaticamente das listas de reprodução após reprodução."),
        "featureDiscoveryPodcast":
            MessageLookupByLibrary.simpleMessage("Vista de podcasts"),
        "featureDiscoveryPodcastDes": MessageLookupByLibrary.simpleMessage(
            "Pode tocar \"Ver todos\" para adicionar grupos ou gerir podcasts."),
        "featureDiscoveryPodcastTitle": MessageLookupByLibrary.simpleMessage(
            "Deslize vertical para trocar de grupo"),
        "featureDiscoverySearch": MessageLookupByLibrary.simpleMessage(
            "Toque para procurar podcasts"),
        "featureDiscoverySearchDes": MessageLookupByLibrary.simpleMessage(
            "Pode procurar pelo título do podcast, palavra-chave ou ligação RSS para subscrever novos podcasts."),
        "feedbackEmail":
            MessageLookupByLibrary.simpleMessage("Envie-me um email"),
        "feedbackGithub":
            MessageLookupByLibrary.simpleMessage("Reportar erros"),
        "feedbackPlay":
            MessageLookupByLibrary.simpleMessage("Avaliar na Play Store"),
        "feedbackTelegram":
            MessageLookupByLibrary.simpleMessage("Entrar no grupo"),
        "filter": MessageLookupByLibrary.simpleMessage("Filtro"),
        "filterType": m32,
        "fontStyle":
            MessageLookupByLibrary.simpleMessage("Estilo do tipo de letra"),
        "fonts": MessageLookupByLibrary.simpleMessage("Fontes"),
        "forward": MessageLookupByLibrary.simpleMessage("Avançar"),
        "from": m7,
        "goodNight": MessageLookupByLibrary.simpleMessage("Boa noite"),
        "gpodderLoginDes": MessageLookupByLibrary.simpleMessage(
            "Parabéns. Acabou de associar a sua conta gpodder.net à aplicação. Agora, já será possível sincronizar as subscrições do seu dispositivo com a conta gpodder.net."),
        "groupExisted": MessageLookupByLibrary.simpleMessage("Grupo já existe"),
        "groupRemoveConfirm": MessageLookupByLibrary.simpleMessage(
            "Tem a certeza de que deseja eliminar este grupo? Os podcasts serão movidos para o grupo Home."),
        "groups": m8,
        "haptics": MessageLookupByLibrary.simpleMessage("Resposta táctil"),
        "hapticsDes": MessageLookupByLibrary.simpleMessage(
            "Ative a resposta táctil e ajuste a sensibilidade. (O dispositivo terá que ter suporte)"),
        "hideListenedSetting":
            MessageLookupByLibrary.simpleMessage("Ocultar reproduzidos"),
        "hidePodcastDiscovery": MessageLookupByLibrary.simpleMessage(
            "Ocultar descoberta de podcasts"),
        "hidePodcastDiscoveryDes": MessageLookupByLibrary.simpleMessage(
            "Ocultar descoberta de podcasts na página de pesquisa"),
        "homeGroupsSeeAll": MessageLookupByLibrary.simpleMessage("Ver tudo"),
        "homeMenuPlaylist":
            MessageLookupByLibrary.simpleMessage("Lista de reprodução"),
        "homeSubMenuSortBy":
            MessageLookupByLibrary.simpleMessage("Ordenar por"),
        "homeTabMenuFavotite": MessageLookupByLibrary.simpleMessage("Favorito"),
        "homeTabMenuRecent": MessageLookupByLibrary.simpleMessage("Recentes"),
        "homeToprightMenuAbout": MessageLookupByLibrary.simpleMessage("Acerca"),
        "homeToprightMenuImportOMPL":
            MessageLookupByLibrary.simpleMessage("Importar OPML"),
        "homeToprightMenuRefreshAll":
            MessageLookupByLibrary.simpleMessage("Atualizar tudo"),
        "hostedOn": m0,
        "hoursAgo": m9,
        "hoursCount": m10,
        "import": MessageLookupByLibrary.simpleMessage("Importar"),
        "importingOpml":
            MessageLookupByLibrary.simpleMessage("A importar OPML."),
        "interaction": MessageLookupByLibrary.simpleMessage("Interação"),
        "intergateWith": m11,
        "introFourthPage": MessageLookupByLibrary.simpleMessage(
            "Toque longo no episódio para ações rápidas."),
        "introSecondPage": MessageLookupByLibrary.simpleMessage(
            "Subscrição de podcasts por pesquisa ou por ficheiro OPML."),
        "introThirdPage": MessageLookupByLibrary.simpleMessage(
            "Pode criar um novo grupo para podcasts."),
        "invalidName":
            MessageLookupByLibrary.simpleMessage("None de utilizador inválido"),
        "lastUpdate":
            MessageLookupByLibrary.simpleMessage("Última atualização"),
        "later": MessageLookupByLibrary.simpleMessage("Mais tarde"),
        "lightMode": MessageLookupByLibrary.simpleMessage("Modo claro"),
        "like": MessageLookupByLibrary.simpleMessage("Gosto"),
        "likeDate": MessageLookupByLibrary.simpleMessage("Data do voto"),
        "liked": MessageLookupByLibrary.simpleMessage("Gostei"),
        "listen": MessageLookupByLibrary.simpleMessage("Reproduzir"),
        "listened": MessageLookupByLibrary.simpleMessage("Reproduzido"),
        "loadAllSelected":
            MessageLookupByLibrary.simpleMessage("Carregar seleção"),
        "loadMore": MessageLookupByLibrary.simpleMessage("Carregar mais"),
        "loading": MessageLookupByLibrary.simpleMessage("A carregar"),
        "localEpisodeDescription": m34,
        "localFolder": MessageLookupByLibrary.simpleMessage("Pasta local"),
        "localFolderDescription": MessageLookupByLibrary.simpleMessage(
            "Pasta que irá receber os ficheiros de áudio importados localmente."),
        "loggedInAs": m1,
        "login": MessageLookupByLibrary.simpleMessage("Iniciar sessão"),
        "loginFailed":
            MessageLookupByLibrary.simpleMessage("Falha ao iniciar sessão"),
        "logout": MessageLookupByLibrary.simpleMessage("Terminar sessão"),
        "mark": MessageLookupByLibrary.simpleMessage("Marcar"),
        "markConfirm": MessageLookupByLibrary.simpleMessage("Confirmação"),
        "markConfirmContent": MessageLookupByLibrary.simpleMessage(
            "Marcar todos os episódios como reproduzidos?"),
        "markListened":
            MessageLookupByLibrary.simpleMessage("Marcar como reproduzido"),
        "markNotListened":
            MessageLookupByLibrary.simpleMessage("Marcar como não reproduzido"),
        "menu": MessageLookupByLibrary.simpleMessage("Menu"),
        "menuAllPodcasts":
            MessageLookupByLibrary.simpleMessage("Todos os podcasts"),
        "menuMarkAllListened": MessageLookupByLibrary.simpleMessage(
            "Marcar todos como reproduzidos"),
        "menuViewRSS":
            MessageLookupByLibrary.simpleMessage("Aceder à fonte RSS"),
        "menuVisitSite": MessageLookupByLibrary.simpleMessage("Aceder ao site"),
        "minsAgo": m12,
        "minsCount": m13,
        "moreOptions": MessageLookupByLibrary.simpleMessage("Mais opções"),
        "network": MessageLookupByLibrary.simpleMessage("Rede"),
        "networkErrorDNS":
            MessageLookupByLibrary.simpleMessage("Erro de rede (DNS)"),
        "neverAutoUpdate": MessageLookupByLibrary.simpleMessage(
            "Desativar atualização automática"),
        "newGroup": MessageLookupByLibrary.simpleMessage("Criar um novo grupo"),
        "newPlain": MessageLookupByLibrary.simpleMessage("Novo"),
        "newestFirst":
            MessageLookupByLibrary.simpleMessage("Mais recentes primeiro"),
        "next": MessageLookupByLibrary.simpleMessage("Seguinte"),
        "noPodcastGroup":
            MessageLookupByLibrary.simpleMessage("Não há podcasts neste grupo"),
        "noShownote": MessageLookupByLibrary.simpleMessage(
            "Não há notas disponíveis para este episódio."),
        "notificaitonFatch": m14,
        "notificationAddingGroups": MessageLookupByLibrary.simpleMessage(
            "Adicionar e organizar grupos."),
        "notificationNetworkError": m15,
        "notificationSubscribe": m16,
        "notificationSubscribeExisted": m17,
        "notificationSubscribing":
            MessageLookupByLibrary.simpleMessage("A subscrever podcasts."),
        "notificationSuccess": m18,
        "notificationUpdate": m19,
        "notificationUpdateError": m20,
        "oldestFirst":
            MessageLookupByLibrary.simpleMessage("Mais antigos primeiro"),
        "passwdRequired":
            MessageLookupByLibrary.simpleMessage("Requer palavra-passe"),
        "password": MessageLookupByLibrary.simpleMessage("Palavra-passe"),
        "pause": MessageLookupByLibrary.simpleMessage("Pausa"),
        "play": MessageLookupByLibrary.simpleMessage("Reproduzir"),
        "playNext": MessageLookupByLibrary.simpleMessage("Reproduzir seguinte"),
        "playNextDes": MessageLookupByLibrary.simpleMessage(
            "Adicionar episódio ao início da lista de reprodução"),
        "playback":
            MessageLookupByLibrary.simpleMessage("Controlo da reprodução"),
        "player": MessageLookupByLibrary.simpleMessage("Reprodutor"),
        "playerHeightMed": MessageLookupByLibrary.simpleMessage("Média"),
        "playerHeightShort": MessageLookupByLibrary.simpleMessage("Pequena"),
        "playerHeightTall": MessageLookupByLibrary.simpleMessage("Grande"),
        "playing": MessageLookupByLibrary.simpleMessage("Em reprodução"),
        "playlistNameEmpty": MessageLookupByLibrary.simpleMessage(
            "Tem que dar um nome à lista de reprodução"),
        "playlists":
            MessageLookupByLibrary.simpleMessage("Listas de reprodução"),
        "plugins": MessageLookupByLibrary.simpleMessage("Plugins"),
        "podcast": m21,
        "podcastSubscribed":
            MessageLookupByLibrary.simpleMessage("Podcast subscrito"),
        "popupMenuDownloadDes":
            MessageLookupByLibrary.simpleMessage("Descarregar episódio"),
        "popupMenuLaterDes": MessageLookupByLibrary.simpleMessage(
            "Adicionar episódio à lista de reprodução"),
        "popupMenuLikeDes": MessageLookupByLibrary.simpleMessage(
            "Adicionar episódio aos favoritos"),
        "popupMenuMarkDes": MessageLookupByLibrary.simpleMessage(
            "Marcar episódio como reproduzido"),
        "popupMenuPlayDes":
            MessageLookupByLibrary.simpleMessage("Reproduzir episódio"),
        "privacyPolicy":
            MessageLookupByLibrary.simpleMessage("Política de privacidade"),
        "publishDate":
            MessageLookupByLibrary.simpleMessage("Data de publicação"),
        "published": m22,
        "publishedDaily":
            MessageLookupByLibrary.simpleMessage("Publicado diariamente"),
        "publishedMonthly":
            MessageLookupByLibrary.simpleMessage("Publicado mensalmente"),
        "publishedWeekly":
            MessageLookupByLibrary.simpleMessage("Publicado semanalmente"),
        "publishedYearly":
            MessageLookupByLibrary.simpleMessage("Publicado anualmente"),
        "queue": MessageLookupByLibrary.simpleMessage("Fila"),
        "random": MessageLookupByLibrary.simpleMessage("Aleatória"),
        "recoverSubscribe":
            MessageLookupByLibrary.simpleMessage("Recuperar subscrição"),
        "refresh": MessageLookupByLibrary.simpleMessage("Atualizar"),
        "refreshArtwork":
            MessageLookupByLibrary.simpleMessage("Atualizar imagens"),
        "remove": MessageLookupByLibrary.simpleMessage("Remover"),
        "removeConfirm":
            MessageLookupByLibrary.simpleMessage("Confirmação de remoção"),
        "removeDownload":
            MessageLookupByLibrary.simpleMessage("Remover descarga"),
        "removeNewMark": MessageLookupByLibrary.simpleMessage("Remover marca"),
        "removePodcastDes": MessageLookupByLibrary.simpleMessage(
            "Tem a certeza de que deseja cancelar a subscrição?"),
        "removedAt": m23,
        "restartAppForEffect": MessageLookupByLibrary.simpleMessage(
            "Tem que reiniciar a aplicação para aplicar as alterações."),
        "save": MessageLookupByLibrary.simpleMessage("Guardar"),
        "schedule": MessageLookupByLibrary.simpleMessage("Horário"),
        "search": MessageLookupByLibrary.simpleMessage("Pesquisa"),
        "searchApi": MessageLookupByLibrary.simpleMessage("API de pesquisa"),
        "searchEngine":
            MessageLookupByLibrary.simpleMessage("Mecanismo de pesquisa"),
        "searchEpisode":
            MessageLookupByLibrary.simpleMessage("Pesquisar episódio"),
        "searchHelper": MessageLookupByLibrary.simpleMessage(
            "Nome do podcast, palavra-chave ou URL."),
        "searchInstructions": MessageLookupByLibrary.simpleMessage(
            "Indique o URL da fonte RSS ou pesquise por um podcast para o adicionar."),
        "searchInvalidRss":
            MessageLookupByLibrary.simpleMessage("Ligação RSS inválida"),
        "searchPodcast":
            MessageLookupByLibrary.simpleMessage("Pesquisar podcasts"),
        "searchWeb": MessageLookupByLibrary.simpleMessage("Pesquisa web"),
        "secCount": m24,
        "secondsAgo": m25,
        "selectMode": MessageLookupByLibrary.simpleMessage("Modo de seleção"),
        "selected": m26,
        "settingStorage": MessageLookupByLibrary.simpleMessage("Armazenamento"),
        "settings": MessageLookupByLibrary.simpleMessage("Definições"),
        "settingsAccentColor":
            MessageLookupByLibrary.simpleMessage("Cor de destaque"),
        "settingsAppIntro": MessageLookupByLibrary.simpleMessage("Introdução"),
        "settingsAppearance": MessageLookupByLibrary.simpleMessage("Aparência"),
        "settingsAppearanceDes":
            MessageLookupByLibrary.simpleMessage("Cores e temas"),
        "settingsAudioCache":
            MessageLookupByLibrary.simpleMessage("Cache de áudio"),
        "settingsAudioCacheDes": MessageLookupByLibrary.simpleMessage(
            "Tamanho máximo da cache de áudio"),
        "settingsAutoDelete":
            MessageLookupByLibrary.simpleMessage("Eliminar descargas após"),
        "settingsAutoDeleteDes":
            MessageLookupByLibrary.simpleMessage("30 dias (padrão)"),
        "settingsAutoPlayDes": MessageLookupByLibrary.simpleMessage(
            "Reproduzir automaticamente o episódio seguinte"),
        "settingsBackup": MessageLookupByLibrary.simpleMessage("Backup"),
        "settingsBackupDes": MessageLookupByLibrary.simpleMessage(
            "Criar backup dos dados da aplicação"),
        "settingsBoostVolume":
            MessageLookupByLibrary.simpleMessage("Nível de aumento de volume"),
        "settingsBoostVolumeDes": MessageLookupByLibrary.simpleMessage(
            "Alterar nível de aumento de volume"),
        "settingsDefaultGrid":
            MessageLookupByLibrary.simpleMessage("Vista de grelha padrão"),
        "settingsDefaultGridDownload":
            MessageLookupByLibrary.simpleMessage("Separador de descargas"),
        "settingsDefaultGridFavorite":
            MessageLookupByLibrary.simpleMessage("Separador de favoritos"),
        "settingsDefaultGridPodcast":
            MessageLookupByLibrary.simpleMessage("Página de podcasts"),
        "settingsDefaultGridRecent":
            MessageLookupByLibrary.simpleMessage("Separador de recentes"),
        "settingsDiscovery":
            MessageLookupByLibrary.simpleMessage("Reiniciar tutorial"),
        "settingsDiscoveryDes": MessageLookupByLibrary.simpleMessage(
            "Tem a certeza de que deseja reativar o tutorial?"),
        "settingsDownloadPosition":
            MessageLookupByLibrary.simpleMessage("Posição da descarga"),
        "settingsEnableSyncing":
            MessageLookupByLibrary.simpleMessage("Ativar sincronização"),
        "settingsEnableSyncingDes": MessageLookupByLibrary.simpleMessage(
            "Atualizar todos os podcasts em segundo plano"),
        "settingsExportDes": MessageLookupByLibrary.simpleMessage(
            "Exportar e importar definições da aplicação"),
        "settingsFastForwardSec":
            MessageLookupByLibrary.simpleMessage("Avanço rápido (segundos)"),
        "settingsFastForwardSecDes": MessageLookupByLibrary.simpleMessage(
            "Altera os segundos do avanço rápido"),
        "settingsFeedback": MessageLookupByLibrary.simpleMessage("Feedback"),
        "settingsFeedbackDes":
            MessageLookupByLibrary.simpleMessage("Erros e sugestões"),
        "settingsHistory": MessageLookupByLibrary.simpleMessage("Histórico"),
        "settingsHistoryDes":
            MessageLookupByLibrary.simpleMessage("Dados de reprodução"),
        "settingsInfo": MessageLookupByLibrary.simpleMessage("Informações"),
        "settingsInterface": MessageLookupByLibrary.simpleMessage("Interface"),
        "settingsLibraries":
            MessageLookupByLibrary.simpleMessage("Bibliotecas"),
        "settingsLibrariesDes": MessageLookupByLibrary.simpleMessage(
            "Bibliotecas de código aberto usados nesta aplicação"),
        "settingsManageDownload":
            MessageLookupByLibrary.simpleMessage("Gerir descargas"),
        "settingsManageDownloadDes": MessageLookupByLibrary.simpleMessage(
            "Gerir ficheiros descarregados"),
        "settingsMarkListenedSkip": MessageLookupByLibrary.simpleMessage(
            "Marcar episódio como reproduzido se ignorado"),
        "settingsMarkListenedSkipDes": MessageLookupByLibrary.simpleMessage(
            "Marcar episódio como reproduzido ao avançar para o seguinte"),
        "settingsMenuAutoPlay":
            MessageLookupByLibrary.simpleMessage("Reprodução contínua"),
        "settingsNetworkCellular": MessageLookupByLibrary.simpleMessage(
            "Perguntar antes de usar dados móveis"),
        "settingsNetworkCellularDes": MessageLookupByLibrary.simpleMessage(
            "Pedir confirmação para usar dados móveis nas descargas de episódios"),
        "settingsPopupMenu":
            MessageLookupByLibrary.simpleMessage("Menu pop-up para episódios"),
        "settingsPopupMenuDes": MessageLookupByLibrary.simpleMessage(
            "Alterar menu pop-up dos episódios"),
        "settingsPrefrence":
            MessageLookupByLibrary.simpleMessage("Preferências"),
        "settingsRewindSec":
            MessageLookupByLibrary.simpleMessage("Recuo rápido (segundos)"),
        "settingsRewindSecDes": MessageLookupByLibrary.simpleMessage(
            "Altera os segundos do recuo rápido"),
        "settingsSTAuto": MessageLookupByLibrary.simpleMessage(
            "Ativação automática do temporizador"),
        "settingsSTAutoDes": MessageLookupByLibrary.simpleMessage(
            "Ativar temporizador no horário definido"),
        "settingsSTDefaultTime":
            MessageLookupByLibrary.simpleMessage("Duração padrão"),
        "settingsSTDefautTimeDes": MessageLookupByLibrary.simpleMessage(
            "Duração padrão para o temporizador"),
        "settingsSTMode":
            MessageLookupByLibrary.simpleMessage("Temporizador automático"),
        "settingsSpeeds": MessageLookupByLibrary.simpleMessage("Velocidades"),
        "settingsSpeedsDes": MessageLookupByLibrary.simpleMessage(
            "Personalizar velocidades disponíveis"),
        "settingsSyncing":
            MessageLookupByLibrary.simpleMessage("Sincronização"),
        "settingsSyncingDes": MessageLookupByLibrary.simpleMessage(
            "Atualizar podcasts em segundo plano"),
        "settingsTapToOpenPopupMenu": MessageLookupByLibrary.simpleMessage(
            "Toque para abrir o menu pop-up"),
        "settingsTapToOpenPopupMenuDes": MessageLookupByLibrary.simpleMessage(
            "Toque longo para abrir a página do episódio"),
        "settingsTheme": MessageLookupByLibrary.simpleMessage("Tema"),
        "share": MessageLookupByLibrary.simpleMessage("Partilhar"),
        "showNotesFonts":
            MessageLookupByLibrary.simpleMessage("Tipo de letra das notas"),
        "size": MessageLookupByLibrary.simpleMessage("Tamanho"),
        "skipSecondsAtEnd":
            MessageLookupByLibrary.simpleMessage("Segundos a ignorar no fim"),
        "skipSecondsAtStart": MessageLookupByLibrary.simpleMessage(
            "Segundos a ignorar no início"),
        "skipSilence": MessageLookupByLibrary.simpleMessage("Ignorar silêncio"),
        "skipToNext":
            MessageLookupByLibrary.simpleMessage("Ir para o seguinte"),
        "sleepTimer": MessageLookupByLibrary.simpleMessage("Temporizador"),
        "sortBy": MessageLookupByLibrary.simpleMessage("Ordenar por"),
        "sortOrder": MessageLookupByLibrary.simpleMessage("Ordenação"),
        "status": MessageLookupByLibrary.simpleMessage("Estado"),
        "statusAuthError":
            MessageLookupByLibrary.simpleMessage("Erro de autenticação"),
        "statusFail": MessageLookupByLibrary.simpleMessage("Falha"),
        "statusSuccess": MessageLookupByLibrary.simpleMessage("Efetuada"),
        "stop": MessageLookupByLibrary.simpleMessage("Parar"),
        "subscribe": MessageLookupByLibrary.simpleMessage("Subscrever"),
        "subscribeExportDes": MessageLookupByLibrary.simpleMessage(
            "Exportar ficheiro OPML de todos os podcasts"),
        "subscribed": MessageLookupByLibrary.simpleMessage("Subscrito"),
        "syncNow": MessageLookupByLibrary.simpleMessage("Sincronizar agora"),
        "systemDefault":
            MessageLookupByLibrary.simpleMessage("Definições do sistema"),
        "timeLastPlayed": m27,
        "timeLeft": m28,
        "to": m29,
        "toastAddPlaylist": MessageLookupByLibrary.simpleMessage(
            "Adicionado à lista de reprodução"),
        "toastDiscovery": MessageLookupByLibrary.simpleMessage(
            "Tutorial reativado, reinicie a aplicação"),
        "toastFileError": MessageLookupByLibrary.simpleMessage(
            "Erro no ficheiro e falha na subscrição"),
        "toastFileNotValid":
            MessageLookupByLibrary.simpleMessage("Ficheiro inválido"),
        "toastHomeGroupNotSupport":
            MessageLookupByLibrary.simpleMessage("Grupo Home não é suportado"),
        "toastImportSettingsSuccess": MessageLookupByLibrary.simpleMessage(
            "Definições importadas com sucesso"),
        "toastOneGroup": MessageLookupByLibrary.simpleMessage(
            "Selecione, pelo menos, um grupo"),
        "toastPodcastRecovering": MessageLookupByLibrary.simpleMessage(
            "A recuperar, espere um pouco"),
        "toastReadFile":
            MessageLookupByLibrary.simpleMessage("Ficheiro lido com sucesso"),
        "toastRecoverFailed": MessageLookupByLibrary.simpleMessage(
            "Não foi possível recuperar o podcast"),
        "toastRemovePlaylist": MessageLookupByLibrary.simpleMessage(
            "Episódio removido da lista de reprodução"),
        "toastSettingSaved":
            MessageLookupByLibrary.simpleMessage("Definições guardadas"),
        "toastTimeEqualEnd": MessageLookupByLibrary.simpleMessage(
            "A hora escolhida é igual à final"),
        "toastTimeEqualStart": MessageLookupByLibrary.simpleMessage(
            "A hora escolhida é igual à inicial"),
        "translators": MessageLookupByLibrary.simpleMessage("Tradutores"),
        "understood": MessageLookupByLibrary.simpleMessage("Percebi"),
        "undo": MessageLookupByLibrary.simpleMessage("Desfazer"),
        "unlike": MessageLookupByLibrary.simpleMessage("Não gosto"),
        "unliked": MessageLookupByLibrary.simpleMessage(
            "Episódio removido dos favoritos"),
        "updateDate":
            MessageLookupByLibrary.simpleMessage("Data de atualização"),
        "updateEpisodesCount": m30,
        "updateFailed": MessageLookupByLibrary.simpleMessage(
            "Falha ao atualizar, erro de ligação"),
        "username": MessageLookupByLibrary.simpleMessage("Nome de utilizador"),
        "usernameRequired":
            MessageLookupByLibrary.simpleMessage("Requer nome de utilizador"),
        "version": m31
      };
}
