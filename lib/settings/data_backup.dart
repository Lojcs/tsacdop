import 'dart:developer' as developer;
import 'dart:io';

import 'package:confetti/confetti.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:line_icons/line_icons.dart';
import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';
import 'package:workmanager/workmanager.dart';

import '../local_storage/key_value_storage.dart';
import '../backup/gpodder_api.dart';
import '../backup/opml_helper.dart';
import '../local_storage/sqflite_localpodcast.dart';
import '../state/settings/tsacdop_settings.dart';
import '../util/extension_helper.dart';
import '../util/helpers.dart';
import '../widgets/custom_widget.dart';
import '../widgets/general_dialog.dart';
import 'settings_widgets.dart';

class DataBackup extends StatelessWidget {
  DataBackup({super.key});

  @override
  Widget build(BuildContext context) {
    final prefCategories = {...PreferenceCategory.values};
    final settingsPasswordController = TextEditingController();
    final databaseCategories = {...DatabaseCategory.values};
    final databasePasswordController = TextEditingController();
    final s = context.s;
    return SettingsPage(
      title: s.settingsBackup,
      sections: [
        SettingsSection(
          title: s.podcastList,
          items: [
            SettingsTile(
              title: s.opmlFile,
              body: Row(
                mainAxisSize: .min,
                children: [
                  SettingsActionButton(
                    onPressed: () async {
                      final file = await exportOmpl(context);
                      await saveExternalFile(file);
                    },
                    baseColor: Colors.green,
                    connectRight: true,
                    icon: Icon(LineIcons.save),
                    text: Text(context.s.save, textAlign: .center),
                  ),
                  SettingsActionButton(
                    onPressed: () async {
                      var file = await exportOmpl(context);
                      await shareFile(file);
                    },
                    baseColor: Colors.blue,
                    connectLeft: true,
                    connectRight: true,
                    icon: Icon(Icons.share),
                    text: Text(context.s.share, textAlign: .center),
                  ),
                  SettingsActionButton(
                    onPressed: () async {
                      var filePickResult = await FilePicker.pickFiles(
                        type: FileType.any,
                      );
                      if (filePickResult != null && context.mounted) {
                        importOpml(
                          context,
                          File(filePickResult.files.first.path!),
                        );
                      }
                    },
                    baseColor: Colors.amber,
                    connectLeft: true,
                    icon: Icon(LineIcons.paperclip),
                    text: Text(context.s.import, textAlign: .center),
                  ),
                ],
              ),
            ),
          ],
        ),
        SettingsSection(
          title: s.settings,
          items: [
            SettingsTile(
              title: s.settingsBackupFile,
              subtitle: s.settingsExportDes,
              body: Row(
                mainAxisSize: .min,
                children: [
                  SettingsActionButton(
                    onPressed: () async {
                      var file = await datedSaveFile("settings", "json");
                      if (context.mounted) {
                        await context.settingState.backup(
                          file,
                          prefCategories,
                          settingsPasswordController.text != ""
                              ? settingsPasswordController.text
                              : null,
                        );
                        await saveExternalFile(file);
                      }
                    },
                    baseColor: Colors.green,
                    connectRight: true,
                    icon: Icon(LineIcons.save),
                    text: Text(context.s.save, textAlign: .center),
                  ),
                  SettingsActionButton(
                    onPressed: () async {
                      var file = await datedSaveFile("settings", "json");
                      if (context.mounted) {
                        await context.settingState.backup(
                          file,
                          prefCategories,
                          settingsPasswordController.text != ""
                              ? settingsPasswordController.text
                              : null,
                        );
                        await shareFile(file);
                      }
                    },
                    baseColor: Colors.blue,
                    connectLeft: true,
                    connectRight: true,
                    icon: Icon(Icons.share),
                    text: Text(context.s.share, textAlign: .center),
                  ),
                  SettingsActionButton(
                    onPressed: () async {
                      final result = await showConfirmationDialog(
                        context,
                        description:
                            s.settingsBackupConfirmationSettingsOverwrite,
                        color: Colors.amber,
                      );
                      if (result) {
                        var filePickResult = await FilePicker.pickFiles(
                          type: FileType.any,
                        );
                        if (filePickResult != null && context.mounted) {
                          final restoreResult = await context.settingState
                              .restore(
                                File(filePickResult.files.first.path!),
                                prefCategories,
                                settingsPasswordController.text != ""
                                    ? settingsPasswordController.text
                                    : null,
                              );
                          if (restoreResult) {
                            await Fluttertoast.showToast(
                              msg: s.toastBackupRestoreSuccess,
                              gravity: ToastGravity.BOTTOM,
                              toastLength: .LENGTH_LONG,
                            );
                          } else {
                            await Fluttertoast.showToast(
                              msg: s.toastBackupRestoreFailure,
                              gravity: ToastGravity.BOTTOM,
                            );
                          }
                        }
                      }
                    },
                    baseColor: Colors.amber,
                    connectLeft: true,
                    connectRight: true,
                    icon: Icon(LineIcons.paperclip),
                    text: Text(context.s.import, textAlign: .center),
                  ),
                  SettingsActionButton(
                    onPressed: () async {
                      final result = await showConfirmationDialog(
                        context,
                        description: s.settingsBackupConfirmationSettingsReset,
                        color: Colors.red,
                      );
                      if (result && context.mounted) {
                        await context.settingState.reset(prefCategories);
                        await Fluttertoast.showToast(
                          msg: s.toastResetSuccessful,
                          gravity: ToastGravity.BOTTOM,
                          toastLength: .LENGTH_LONG,
                        );
                      }
                    },
                    baseColor: Colors.red,
                    connectLeft: true,
                    icon: Icon(Icons.restore),
                    text: Text(context.s.settingsReset, textAlign: .center),
                  ),
                ],
              ),
            ),
            SettingsTile(
              title: s.settingsBackupCategories,
              subtitle: s.settingsBackupCategoriesDes,
              onTap: (context) {
                final options = PreferenceCategory.values;
                if (context.mounted) {
                  showGeneralSheet(
                    context,
                    title: s.settingsBackupCategories,
                    child: StatefulBuilder(
                      builder: (context, setState) => Column(
                        children: options
                            .map((option) {
                              final title = prefCategoryToString(
                                context,
                                option,
                              );
                              if (title != null) {
                                return CheckboxListTile(
                                  title: Text(title),
                                  value: prefCategories.contains(option),
                                  onChanged: (value) {
                                    if (value!) {
                                      prefCategories.add(option);
                                    } else {
                                      prefCategories.remove(option);
                                    }
                                    setState(() {});
                                  },
                                );
                              }
                            })
                            .nonNulls
                            .toList(),
                      ),
                    ),
                  );
                }
              },
            ),
            SettingsTile(
              title: s.settingsBackupPassword,
              subtitle: s.settingsBackupPasswordDes,
              body: TextFormField(
                textAlign: .center,
                decoration: InputDecoration(
                  hintText: s.password,
                  isDense: true,
                  border: InputBorder.none,
                ),
                obscureText: true,
                controller: settingsPasswordController,
              ),
            ),
          ],
        ),
        SettingsSection(
          title: s.settingsLegacy,
          items: [
            SettingsTile(
              title: s.settingsBackupLegacyFile,
              subtitle: s.settingsBackupLegacyFileDes,
              body: SettingsActionButton(
                onPressed: () async {
                  final result = await showConfirmationDialog(
                    context,
                    description: s.settingsBackupConfirmationSettingsOverwrite,
                    color: Colors.amber,
                  );
                  if (result) {
                    var filePickResult = await FilePicker.pickFiles(
                      type: FileType.any,
                    );
                    if (filePickResult != null && context.mounted) {
                      final restoreResult = await context.settingState
                          .restoreLegacy(
                            File(filePickResult.files.first.path!),
                            prefCategories,
                          );
                      if (restoreResult) {
                        await Fluttertoast.showToast(
                          msg: s.toastBackupRestoreSuccess,
                          gravity: ToastGravity.BOTTOM,
                          toastLength: .LENGTH_LONG,
                        );
                      } else {
                        await Fluttertoast.showToast(
                          msg: s.toastBackupRestoreFailure,
                          gravity: ToastGravity.BOTTOM,
                        );
                      }
                    }
                  }
                },
                baseColor: Colors.amber,
                icon: Icon(LineIcons.paperclip),
                text: Text(context.s.import, textAlign: .center),
              ),
            ),
            SettingsTile(
              title: s.settingsBackupCategories,
              subtitle: s.settingsBackupCategoriesImportDes,
              onTap: (context) {
                final options = PreferenceCategory.values;
                if (context.mounted) {
                  showGeneralSheet(
                    context,
                    title: s.settingsBackupCategories,
                    child: StatefulBuilder(
                      builder: (context, setState) => Column(
                        children: options
                            .map((option) {
                              final title = prefCategoryToString(
                                context,
                                option,
                              );
                              if (title != null) {
                                return CheckboxListTile(
                                  title: Text(title),
                                  value: prefCategories.contains(option),
                                  onChanged: (value) {
                                    if (value!) {
                                      prefCategories.add(option);
                                    } else {
                                      prefCategories.remove(option);
                                    }
                                    setState(() {});
                                  },
                                );
                              }
                            })
                            .nonNulls
                            .toList(),
                      ),
                    ),
                  );
                }
              },
            ),
          ],
        ),
        SettingsSection(
          title: s.settingsBackupDatabase,
          items: [
            SettingsTile(
              title: s.settingsBackupDatabaseBackupFile,
              subtitle: s.settingsBackupDatabaseBackupFileDes,
              body: Row(
                mainAxisSize: .min,
                children: [
                  SettingsActionButton(
                    onPressed: () async {
                      var file = await datedSaveFile("database", "db3");
                      if (context.mounted) {
                        await DBHelper().backup(
                          file,
                          databaseCategories,
                          databasePasswordController.text != ""
                              ? databasePasswordController.text
                              : null,
                        );
                        await saveExternalFile(file);
                      }
                    },
                    baseColor: Colors.green,
                    connectRight: true,
                    icon: Icon(LineIcons.save),
                    text: Text(context.s.save, textAlign: .center),
                  ),
                  SettingsActionButton(
                    onPressed: () async {
                      var file = await datedSaveFile("database", "db3");
                      if (context.mounted) {
                        await DBHelper().backup(
                          file,
                          databaseCategories,
                          databasePasswordController.text != ""
                              ? databasePasswordController.text
                              : null,
                        );
                        await shareFile(file);
                      }
                    },
                    baseColor: Colors.blue,
                    connectLeft: true,
                    connectRight: true,
                    icon: Icon(Icons.share),
                    text: Text(context.s.share, textAlign: .center),
                  ),
                  SettingsActionButton(
                    onPressed: () async {
                      final result = await showConfirmationDialog(
                        context,
                        description:
                            s.settingsBackupConfirmationDatabaseOverwrite,
                        color: Colors.amber,
                      );
                      if (result) {
                        var filePickResult = await FilePicker.pickFiles(
                          type: FileType.any,
                        );
                        if (filePickResult != null && context.mounted) {
                          final restoreResult = await DBHelper().restore(
                            File(filePickResult.files.first.path!),
                            databaseCategories,
                            databasePasswordController.text != ""
                                ? databasePasswordController.text
                                : null,
                            context.downloadState,
                          );
                          if (restoreResult) {
                            await Fluttertoast.showToast(
                              msg: s.toastBackupRestoreSuccess,
                              gravity: ToastGravity.BOTTOM,
                              toastLength: .LENGTH_LONG,
                            );
                            await Fluttertoast.showToast(
                              msg: s.toastRestart,
                              gravity: ToastGravity.BOTTOM,
                              toastLength: .LENGTH_LONG,
                            );
                          } else {
                            await Fluttertoast.showToast(
                              msg: s.toastBackupRestoreFailure,
                              gravity: ToastGravity.BOTTOM,
                            );
                          }
                        }
                      }
                    },
                    baseColor: Colors.amber,
                    connectLeft: true,
                    connectRight: true,
                    icon: Icon(LineIcons.paperclip),
                    text: Text(s.import, textAlign: .center),
                  ),
                  SettingsActionButton(
                    onPressed: () async {
                      final result = await showConfirmationDialog(
                        context,
                        description: s.settingsBackupConfirmationDatabaseReset,
                        color: Colors.red,
                      );
                      if (result && context.mounted) {
                        await DBHelper().reset(
                          databaseCategories,
                          context.downloadState,
                        );
                        await Fluttertoast.showToast(
                          msg: s.toastResetSuccessful,
                          gravity: ToastGravity.BOTTOM,
                          toastLength: .LENGTH_LONG,
                        );
                        await Fluttertoast.showToast(
                          msg: s.toastRestart,
                          gravity: ToastGravity.BOTTOM,
                          toastLength: .LENGTH_LONG,
                        );
                      }
                    },
                    baseColor: Colors.red,
                    connectLeft: true,
                    icon: Icon(Icons.restore),
                    text: Text(context.s.settingsReset, textAlign: .center),
                  ),
                ],
              ),
            ),
            SettingsTile(
              title: s.settingsBackupCategories,
              subtitle: s.settingsBackupDatabaseCategoriesDes,
              onTap: (context) {
                final options = DatabaseCategory.values;
                if (context.mounted) {
                  showGeneralSheet(
                    context,
                    title: s.settingsBackupCategories,
                    child: StatefulBuilder(
                      builder: (context, setState) => Column(
                        children: options
                            .map((option) {
                              final title = databaseCategoryToString(
                                context,
                                option,
                              );
                              if (title != null) {
                                return CheckboxListTile(
                                  title: Text(title),
                                  value: databaseCategories.contains(option),
                                  onChanged: (value) {
                                    if (value!) {
                                      databaseCategories.add(option);
                                    } else {
                                      databaseCategories.remove(option);
                                    }
                                    setState(() {});
                                  },
                                );
                              }
                            })
                            .nonNulls
                            .toList(),
                      ),
                    ),
                  );
                }
              },
            ),
            SettingsTile(
              title: s.settingsBackupPassword,
              subtitle: s.settingsBackupPasswordDes,
              body: TextFormField(
                textAlign: .center,
                decoration: InputDecoration(
                  hintText: s.password,
                  isDense: true,
                  border: InputBorder.none,
                ),
                obscureText: true,
                controller: databasePasswordController,
              ),
            ),
          ],
        ),
      ],
    );
  }

  String? prefCategoryToString(
    BuildContext context,
    PreferenceCategory prefClass,
  ) => switch (prefClass) {
    .meta => null,
    .times => null,
    .general => context.s.settingsGeneral,
    .lookAndFeel => context.s.settingsLookAndFeel,
    .interface => context.s.settingsInterface,
    .playback => context.s.settingsPlayback,
    .sleepTimer => context.s.sleepTimer,
    .playerState => context.s.settingsPlayerState,
    .sync => context.s.settingsSyncing,
    .download => context.s.settingsDownloads,
  };

  String? databaseCategoryToString(
    BuildContext context,
    DatabaseCategory prefClass,
  ) => switch (prefClass) {
    .podcasts => context.s.settingsBackupDatabasePodcasts,
    .history => context.s.settingsBackupDatabaseHistory,
    .playlists => context.s.settingsBackupDatabasePlaylists,
  };

  Widget _syncStauts(int? index) {
    switch (index) {
      case 1:
        return Text('Successed', style: TextStyle(color: Colors.green));
      case 2:
        return Text('Failed', style: TextStyle(color: Colors.red));
      case 3:
        return Text('Unauthorized', style: TextStyle(color: Colors.red));
      default:
        return Text('Unknown');
    }
  }

  final _gpodder = Gpodder();
  Future<void> _logout() async {
    await _gpodder.logout();
    // Stop sync also
    Fluttertoast.showToast(
      msg: 'Logout successfully',
      gravity: ToastGravity.BOTTOM,
    );
    // if (mounted) setState(() {});
  }

  Future<List<String?>?> _getLoginInfo() async {
    return await KeyValueStorage().getStringList(gpodderApiKey);
  }

  Future<List<int?>> _getSyncStatus() async {
    final syncDateTime = await KeyValueStorage().getInt(gpodderSyncDateTimeKey);
    final statusIndex = await KeyValueStorage().getInt(gpodderSyncStatusKey);
    return [syncDateTime, statusIndex];
  }
}

@pragma('vm:entry-point')
void callbackDispatcher() {
  if (Platform.isAndroid) {
    Workmanager().executeTask((task, inputData) async {
      final gpodder = Gpodder();
      final status = await gpodder.getChanges();
      if (status == 200) {
        await gpodder.updateChange();
        developer.log('Gpodder sync successfully');
      }
      return Future.value(true);
    });
  }
}

enum LoginStatus { none, error, start, syncing, complete }

class _LoginGpodder extends StatefulWidget {
  const _LoginGpodder();

  @override
  __LoginGpodderState createState() => __LoginGpodderState();
}

class __LoginGpodderState extends State<_LoginGpodder> {
  String? _username = '';
  var _password = '';
  LoginStatus? _loginStatus;
  late ConfettiController _controller;

  @override
  void initState() {
    _loginStatus = LoginStatus.none;
    _controller = ConfettiController(duration: Duration(seconds: 3));
    super.initState();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  final GlobalKey<FormFieldState<String>> _passwordFieldKey =
      GlobalKey<FormFieldState<String>>();
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final _gpodder = Gpodder();

  Future<void> _handleLogin() async {
    setState(() => _loginStatus = LoginStatus.start);
    final form = _formKey.currentState!;
    if (form.validate()) {
      form.save();
      final status = await _gpodder.login(
        username: _username,
        password: _password,
      );
      if (status == 200) {
        final updateDevice = await _gpodder.updateDevice(_username);
        if (updateDevice == 200) {
          if (mounted) {
            setState(() {
              _loginStatus = LoginStatus.syncing;
            });
          }
          final uploadStatus = await _gpodder.uploadSubscriptions();
          await _getSubscriptions(_gpodder);
          if (uploadStatus == 200) {
            if (mounted) {
              setState(() {
                _loginStatus = LoginStatus.complete;
                _controller.play();
              });
            }
          }
        } else {
          if (mounted) setState(() => _loginStatus = LoginStatus.error);
          Fluttertoast.showToast(
            msg: context.s.loginFailed,
            gravity: ToastGravity.BOTTOM,
          );
        }
      } else {
        if (mounted) setState(() => _loginStatus = LoginStatus.error);
        Fluttertoast.showToast(
          msg: context.s.loginFailed,
          gravity: ToastGravity.BOTTOM,
        );
      }
    } else {
      if (mounted) setState(() => _loginStatus = LoginStatus.none);
    }
  }

  Future<void> _getSubscriptions(Gpodder gpodder) async {
    await Workmanager().cancelByUniqueName('2');
    developer.log('work job cancelled');
    var pState = context.podcastState;
    final opml = await gpodder.getAllPodcast();
    if (opml != null && opml != '') {
      pState.subscribeOpml(opml);
    }
    await Workmanager().initialize(callbackDispatcher, isInDebugMode: false);
    await Workmanager().registerPeriodicTask(
      "2",
      "gpodder_sync",
      frequency: Duration(hours: 4),
      initialDelay: Duration(seconds: 10),
      constraints: Constraints(networkType: NetworkType.connected),
    );
    developer.log('work manager init done + (gpodder sync)');
  }

  String? _validateName(String? value) {
    if (value!.isEmpty) {
      return context.s.usernameRequired;
    }
    final nameExp = RegExp(r'^[A-Za-z ]+$');
    if (!nameExp.hasMatch(value)) {
      return context.s.invalidName;
    }
    return null;
  }

  String? _validatePassword(String? value) {
    final passwordField = _passwordFieldKey.currentState!;
    if (passwordField.value == null || passwordField.value!.isEmpty) {
      return context.s.passwdRequired;
    }
    return null;
  }

  Widget _loginStatusButton() {
    switch (_loginStatus) {
      case LoginStatus.none:
        return Text(context.s.login, style: TextStyle(color: Colors.white));
      case LoginStatus.syncing:
        return Text(
          context.s.settingsSyncing,
          style: TextStyle(color: Colors.white),
        );
      case LoginStatus.start:
        return SizedBox(
          height: 20,
          width: 20,
          child: CircularProgressIndicator(
            strokeWidth: 2,
            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
          ),
        );
      default:
        return Text(context.s.login, style: TextStyle(color: Colors.white));
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = context.s;
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: context.overlay,
      child: Scaffold(
        resizeToAvoidBottomInset: true,
        body: SafeArea(
          top: false,
          child: CustomScrollView(
            slivers: [
              SliverAppBar(
                iconTheme: IconThemeData(color: Colors.white),
                elevation: 0,
                leading: CustomBackButton(),
                backgroundColor: context.primaryColor,
                expandedHeight: 200,
                flexibleSpace: Container(
                  height: 200,
                  width: double.infinity,
                  color: context.primaryColor,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      Hero(
                        tag: 'gpodder.net',
                        child: CircleAvatar(
                          minRadius: 50,
                          backgroundColor: context.onPrimary.withValues(
                            alpha: 0.3,
                          ),
                          child: SizedBox(
                            height: 80,
                            width: 80,
                            child: Image.asset('assets/gpodder.png'),
                          ),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Text(
                          s.intergateWith('gpodder.net'),
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                systemOverlayStyle: SystemUiOverlayStyle.light,
              ),
              _loginStatus == LoginStatus.complete
                  ? SliverList(
                      delegate: SliverChildListDelegate([
                        Stack(
                          children: [
                            Padding(
                              padding: const EdgeInsets.fromLTRB(
                                40.0,
                                50,
                                40,
                                100,
                              ),
                              child: Text(
                                s.gpodderLoginDes,
                                textAlign: TextAlign.center,
                                style: context.textTheme.titleMedium!.copyWith(
                                  height: 2,
                                ),
                              ),
                            ),
                            Align(
                              alignment: Alignment.center,
                              child: ConfettiWidget(
                                confettiController: _controller,
                                blastDirectionality:
                                    BlastDirectionality.explosive,
                                emissionFrequency: 0.05,
                                maximumSize: Size(20, 10),
                                shouldLoop: false,
                                colors: const [
                                  Colors.green,
                                  Colors.blue,
                                  Colors.pink,
                                  Colors.orange,
                                  Colors.purple,
                                ],
                              ),
                            ),
                          ],
                        ),
                        Center(
                          child: OutlinedButton(
                            onPressed: () {
                              Navigator.of(context).pop();
                            },
                            style: OutlinedButton.styleFrom(
                              side: BorderSide(color: context.primaryColor),
                            ),
                            child: Text(s.back),
                          ),
                        ),
                      ]),
                    )
                  : Form(
                      key: _formKey,
                      autovalidateMode: AutovalidateMode.disabled,
                      child: AutofillGroup(
                        child: SliverList(
                          delegate: SliverChildListDelegate([
                            Padding(
                              padding: const EdgeInsets.fromLTRB(
                                40,
                                20,
                                40,
                                10,
                              ),
                              child: TextFormField(
                                decoration: InputDecoration(
                                  labelStyle: TextStyle(
                                    color: context.primaryColor,
                                  ),
                                  focusColor: context.primaryColor,
                                  focusedBorder: OutlineInputBorder(
                                    borderSide: BorderSide(
                                      color: context.primaryColor,
                                      width: 2,
                                    ),
                                  ),
                                  border: OutlineInputBorder(
                                    borderSide: BorderSide(
                                      color: context.primaryColor,
                                    ),
                                  ),
                                  labelText: s.username,
                                ),
                                maxLines: 1,
                                autofocus: true,
                                validator: _validateName,
                                autofillHints: [AutofillHints.username],
                                onSaved: (value) {
                                  setState(() => _username = value);
                                },
                              ),
                            ),
                            Padding(
                              padding: const EdgeInsets.fromLTRB(
                                40,
                                10,
                                40,
                                20,
                              ),
                              child: PasswordField(
                                fieldKey: _passwordFieldKey,
                                labelText: s.password,
                                validator: _validatePassword,
                                onSaved: (value) {
                                  if (value == null) {
                                    return setState(() {
                                      _password = value!;
                                    });
                                  }
                                },
                              ),
                            ),
                            Padding(
                              padding: const EdgeInsets.fromLTRB(
                                40,
                                10,
                                40,
                                20,
                              ),
                              child: InkWell(
                                onTap: () {
                                  _handleLogin();
                                },
                                borderRadius: BorderRadius.circular(5.0),
                                child: Container(
                                  height: 40,
                                  width: 150,
                                  decoration: BoxDecoration(
                                    color: context.primaryColor,
                                    borderRadius: BorderRadius.circular(5.0),
                                  ),
                                  child: Center(child: _loginStatusButton()),
                                ),
                              ),
                            ),
                            SizedBox(
                              height: MediaQuery.of(context).viewInsets.bottom,
                            ),
                          ]),
                        ),
                      ),
                    ),
            ],
          ),
        ),
      ),
    );
  }
}

class PasswordField extends StatefulWidget {
  const PasswordField({
    super.key,
    this.fieldKey,
    this.hintText,
    this.labelText,
    this.helperText,
    this.onSaved,
    this.validator,
    this.onFieldSubmitted,
  });

  final Key? fieldKey;
  final String? hintText;
  final String? labelText;
  final String? helperText;
  final FormFieldSetter<String>? onSaved;
  final FormFieldValidator<String>? validator;
  final ValueChanged<String>? onFieldSubmitted;

  @override
  _PasswordFieldState createState() => _PasswordFieldState();
}

class _PasswordFieldState extends State<PasswordField> {
  bool _obscureText = true;

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      key: widget.fieldKey,
      obscureText: _obscureText,
      autofillHints: [AutofillHints.password],
      maxLength: 100,
      onSaved: widget.onSaved,
      validator: widget.validator,
      onFieldSubmitted: widget.onFieldSubmitted,
      decoration: InputDecoration(
        hintStyle: TextStyle(color: context.primaryColor),
        labelStyle: TextStyle(color: context.primaryColor),
        border: OutlineInputBorder(
          borderSide: BorderSide(color: context.primaryColor),
        ),
        focusedBorder: OutlineInputBorder(
          borderSide: BorderSide(color: context.primaryColor, width: 2),
        ),
        hintText: widget.hintText,
        labelText: widget.labelText,
        helperText: widget.helperText,
        suffixIcon: GestureDetector(
          dragStartBehavior: DragStartBehavior.down,
          onTap: () {
            setState(() {
              _obscureText = !_obscureText;
            });
          },
          child: Icon(
            _obscureText ? Icons.visibility : Icons.visibility_off,
            color: context.primaryColor,
            semanticLabel: _obscureText ? 'Show' : 'Hide',
          ),
        ),
      ),
    );
  }
}

class _GpodderInfo extends StatefulWidget {
  const _GpodderInfo();

  @override
  __GpodderInfoState createState() => __GpodderInfoState();
}

class __GpodderInfoState extends State<_GpodderInfo> {
  final _gpodder = Gpodder();
  var _syncing = false;
  final _gpodderUrl = "https://gpodder.net";

  Future<List<String>?> _getLoginInfo() async {
    final androidInfo = await DeviceInfoPlugin().androidInfo;
    final deviceInfo = await KeyValueStorage().getStringList(gpodderApiKey);
    deviceInfo!.add("Tsacdop on ${androidInfo.model}");
    return deviceInfo;
  }

  Future<void> _fullSync() async {
    final pState = context.podcastState;
    if (mounted) {
      setState(() {
        _syncing = true;
      });
    }
    final uploadStatus = await _gpodder.uploadSubscriptions();
    if (uploadStatus == 200) {
      final opml = await _gpodder.getAllPodcast();
      if (opml != null && opml != '') {
        pState.subscribeOpml(opml);
      }
    }
    //await _syncNow();
    if (mounted) {
      setState(() {
        _syncing = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: context.overlay,
      child: Scaffold(
        resizeToAvoidBottomInset: true,
        body: SafeArea(
          top: false,
          child: CustomScrollView(
            slivers: [
              SliverAppBar(
                iconTheme: IconThemeData(color: Colors.white),
                leading: CustomBackButton(),
                elevation: 0,
                backgroundColor: context.primaryColor,
                expandedHeight: 200,
                flexibleSpace: Container(
                  height: 200,
                  width: double.infinity,
                  color: context.primaryColor,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      CircleAvatar(
                        minRadius: 50,
                        backgroundColor: context.onPrimary.withValues(
                          alpha: 0.3,
                        ),
                        child: SizedBox(
                          height: 80,
                          width: 80,
                          child: Image.asset('assets/gpodder.png'),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Text(
                          'gpodder.net',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                systemOverlayStyle: SystemUiOverlayStyle.light,
              ),
              SliverList(
                delegate: SliverChildListDelegate([
                  FutureBuilder<List<String>?>(
                    future: _getLoginInfo(),
                    initialData: [],
                    builder: (context, snapshot) {
                      final deviceId = snapshot.data!.isNotEmpty
                          ? snapshot.data![1]
                          : '';
                      final deviceName = snapshot.data!.isNotEmpty
                          ? snapshot.data![3]
                          : '';
                      return Column(
                        children: [
                          ListTile(
                            title: Text('Device id'),
                            subtitle: Text(deviceId),
                          ),
                          ListTile(
                            title: Text('Device name'),
                            subtitle: Text(deviceName),
                          ),
                        ],
                      );
                    },
                  ),
                  ListTile(
                    onTap: _gpodderUrl.launchUrl,
                    title: Text('Visit gpodder.net'),
                    subtitle: Text('Manage subscriptions online'),
                  ),
                  ListTile(
                    onTap: _fullSync,
                    title: Text('Full sync'),
                    subtitle: Text('If error happened when syncing'),
                  ),
                ]),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
