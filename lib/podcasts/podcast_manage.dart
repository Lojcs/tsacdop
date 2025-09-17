import 'dart:math' as math;

import 'package:feature_discovery/feature_discovery.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:line_icons/line_icons.dart';
import 'package:provider/provider.dart';

import '../state/podcast_state.dart';
import '../state/setting_state.dart';
import '../type/podcastgroup.dart';
import '../util/extension_helper.dart';
import '../util/pageroute.dart';
import '../widgets/custom_widget.dart';
import '../widgets/feature_discovery.dart';
import '../widgets/general_dialog.dart';
import 'custom_tabview.dart';
import 'podcast_group.dart';
import 'podcastlist.dart';

class PodcastManage extends StatefulWidget {
  const PodcastManage({super.key});

  @override
  _PodcastManageState createState() => _PodcastManageState();
}

class _PodcastManageState extends State<PodcastManage>
    with TickerProviderStateMixin {
  bool _showSetting = false;
  double _menuValue = 0;
  late AnimationController _menuController;
  late Animation _menuAnimation;
  int _index = 0;

  @override
  void initState() {
    super.initState();
    _menuController = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 300));
    _menuAnimation = Tween(begin: 0.0, end: 1.0)
        .animate(CurvedAnimation(parent: _menuController, curve: Curves.ease))
      ..addListener(() {
        if (mounted) setState(() => _menuValue = _menuAnimation.value);
      });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      FeatureDiscovery.discoverFeatures(context,
          const <String>{addGroupFeature, configureGroup, configurePodcast});
    });
  }

  @override
  void dispose() {
    _menuController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final s = context.s;
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: context.overlay,
      child: Scaffold(
        appBar: AppBar(
          backgroundColor: context.surface,
          title: Text(context.s.groups(2)),
          leading: CustomBackButton(),
          actions: <Widget>[
            featureDiscoveryOverlay(
              context,
              featureId: addGroupFeature,
              tapTarget: Icon(Icons.add),
              title: s.featureDiscoveryGroup,
              backgroundColor: Colors.cyan[600],
              description: s.featureDiscoveryGroupDes,
              buttonColor: Colors.cyan[500],
              child: IconButton(
                  splashRadius: 20,
                  onPressed: () => showGeneralDialog(
                      context: context,
                      barrierDismissible: true,
                      barrierLabel: MaterialLocalizations.of(context)
                          .modalBarrierDismissLabel,
                      barrierColor: Colors.black54,
                      transitionDuration: const Duration(milliseconds: 200),
                      pageBuilder: (context, animaiton, secondaryAnimation) =>
                          AddGroup()),
                  icon: Icon(Icons.add_circle_outline)),
            ),
            Selector<SettingState, bool?>(
              selector: (_, setting) => setting.openAllPodcastDefalt,
              builder: (_, data, __) {
                return !data!
                    ? IconButton(
                        splashRadius: 20,
                        onPressed: () => Navigator.push(
                            context, ScaleRoute(page: PodcastList())),
                        icon: Icon(Icons.all_out))
                    : Center();
              },
            )
          ],
        ),
        body: SafeArea(
          child: Selector<PodcastState, List<String>>(
            selector: (_, pState) => pState.groupIds,
            builder: (context, groupIds, _) {
              if (groupIds.isEmpty) return Center();
              return Stack(
                children: <Widget>[
                  ColoredBox(
                    color: context.surface,
                    child: CustomTabView(
                      itemCount: groupIds.length,
                      tabBuilder: (context, index) => Tab(
                        child: Container(
                          height: 50.0,
                          padding: EdgeInsets.symmetric(horizontal: 20.0),
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(15),
                          ),
                          child: Selector<PodcastState, String>(
                            selector: (_, pState) =>
                                pState.getGroupById(groupIds[index])!.name,
                            builder: (context, name, _) => Text(name),
                          ),
                        ),
                      ),
                      pageBuilder: (context, index) => featureDiscoveryOverlay(
                        context,
                        featureId: configurePodcast,
                        tapTarget: Text(s.podcast(1)),
                        title: s.featureDiscoveryGroupPodcast,
                        backgroundColor: Colors.cyan[600],
                        buttonColor: Colors.cyan[500],
                        description: s.featureDiscoveryGroupPodcastDes,
                        child: PodcastGroupList(
                          groupId: groupIds[index],
                          key: ValueKey<String?>(groupIds[index]),
                        ),
                      ),
                      onPositionChange: (value) {
                        // setState(() =>
                        if (value != null) _index = value;
                      },
                    ),
                  ),
                  if (_showSetting)
                    Positioned.fill(
                      top: 50,
                      child: GestureDetector(
                        onTap: () async {
                          await _menuController.reverse();
                          if (mounted) {
                            setState(() => _showSetting = false);
                          }
                        },
                        child: Container(
                          color: context.surface.withValues(
                              alpha: 0.8 *
                                  math.min(_menuController.value * 2, 1.0)),
                        ),
                      ),
                    ),
                  Positioned(
                    right: 30,
                    bottom: 30,
                    child: _faButton(),
                  ),
                  if (_showSetting)
                    Positioned(
                      right: 100 * _menuValue - 70,
                      bottom: 100,
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.start,
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: <Widget>[
                          Material(
                            color: Colors.transparent,
                            child: InkWell(
                              onTap: () {
                                _menuController.reverse();
                                setState(() => _showSetting = false);
                                _index == 0
                                    ? Fluttertoast.showToast(
                                        msg: s.toastHomeGroupNotSupport,
                                        gravity: ToastGravity.BOTTOM,
                                      )
                                    : showGeneralDialog(
                                        context: context,
                                        barrierDismissible: true,
                                        barrierLabel:
                                            MaterialLocalizations.of(context)
                                                .modalBarrierDismissLabel,
                                        barrierColor: Colors.black54,
                                        transitionDuration:
                                            const Duration(milliseconds: 300),
                                        pageBuilder: (context, animaiton,
                                                secondaryAnimation) =>
                                            RenameGroup(
                                          groupId: groupIds[_index!],
                                        ),
                                      );
                              },
                              child: Container(
                                height: 30.0,
                                decoration: BoxDecoration(
                                    color: Colors.grey[700],
                                    borderRadius: BorderRadius.circular(10.0)),
                                padding: EdgeInsets.symmetric(horizontal: 10),
                                child: Row(
                                  children: <Widget>[
                                    Icon(
                                      Icons.text_fields,
                                      color: Colors.white,
                                      size: 15.0,
                                    ),
                                    Padding(
                                      padding:
                                          EdgeInsets.symmetric(horizontal: 5.0),
                                    ),
                                    Text(context.s.editGroupName,
                                        style: TextStyle(color: Colors.white)),
                                  ],
                                ),
                              ),
                            ),
                          ),
                          SizedBox(height: 20),
                          Material(
                            color: Colors.transparent,
                            child: InkWell(
                              onTap: () {
                                _menuController.reverse();
                                setState(() => _showSetting = false);
                                _index == 0
                                    ? Fluttertoast.showToast(
                                        msg: s.toastHomeGroupNotSupport,
                                        gravity: ToastGravity.BOTTOM,
                                      )
                                    : generalDialog(
                                        context,
                                        title: Text(s.removeConfirm),
                                        content: Text(s.groupRemoveConfirm),
                                        actions: <Widget>[
                                          TextButton(
                                            onPressed: () =>
                                                Navigator.of(context).pop(),
                                            child: Text(
                                              context.s.cancel,
                                              style: TextStyle(
                                                  color: Colors.grey[600]),
                                            ),
                                          ),
                                          TextButton(
                                            onPressed: () {
                                              context.podcastState.removeGroup(
                                                  groupIds[_index]);
                                              if (_index ==
                                                  context.podcastState.groupIds
                                                          .length -
                                                      1) {
                                                setState(() {
                                                  _index = _index - 1;
                                                });
                                              }
                                              Navigator.of(context).pop();
                                            },
                                            child: Text(
                                              context.s.confirm,
                                              style:
                                                  TextStyle(color: Colors.red),
                                            ),
                                          )
                                        ],
                                      );
                              },
                              child: Container(
                                height: 30,
                                decoration: BoxDecoration(
                                    color: Colors.grey[700],
                                    borderRadius: BorderRadius.circular(10.0)),
                                padding: EdgeInsets.symmetric(horizontal: 10),
                                child: Row(
                                  children: <Widget>[
                                    Icon(
                                      Icons.delete,
                                      color: Colors.red,
                                      size: 15.0,
                                    ),
                                    SizedBox(width: 10),
                                    Text(s.remove,
                                        style: TextStyle(color: Colors.red)),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _faButton() {
    final s = context.s;
    return featureDiscoveryOverlay(
      context,
      featureId: configureGroup,
      tapTarget: Icon(Icons.menu),
      title: s.featureDiscoveryEditGroup,
      backgroundColor: Colors.cyan[600],
      description: s.featureDiscoveryEditGroupDes,
      buttonColor: Colors.cyan[500],
      child: InkWell(
        onTap: () async {
          !_showSetting
              ? _menuController.forward()
              : await _menuController.reverse();
          if (mounted) {
            setState(() {
              _showSetting = !_showSetting;
            });
          }
        },
        child: Container(
          width: 50,
          height: 50,
          decoration: BoxDecoration(
              color: context.accentColor,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: Colors.grey[700]!.withValues(alpha: 0.5),
                  blurRadius: 1,
                  offset: Offset(1, 1),
                ),
              ]),
          alignment: Alignment.center,
          child: AnimatedIcon(
            color: Colors.white,
            icon: AnimatedIcons.menu_close,
            progress: _menuController,
          ),
        ),
      ),
    );
  }
}

class AddGroup extends StatefulWidget {
  const AddGroup({super.key});

  @override
  _AddGroupState createState() => _AddGroupState();
}

class _AddGroupState extends State<AddGroup> {
  TextEditingController? _controller;
  String? _newGroup;
  int? _error;

  @override
  void initState() {
    super.initState();
    _error = 0;
    _controller = TextEditingController();
  }

  @override
  void dispose() {
    _controller!.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final s = context.s;
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        systemNavigationBarColor:
            Theme.of(context).brightness == Brightness.light
                ? Color.fromRGBO(113, 113, 113, 1)
                : Color.fromRGBO(5, 5, 5, 1),
      ),
      child: SafeArea(
        top: false,
        child: AlertDialog(
          backgroundColor: context.accentBackgroundWeak,
          shape: RoundedRectangleBorder(
            borderRadius: context.radiusMedium,
          ),
          elevation: 1,
          contentPadding: EdgeInsets.symmetric(horizontal: 20),
          titlePadding: EdgeInsets.all(20),
          actionsPadding: EdgeInsets.zero,
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(
                s.cancel,
                style: TextStyle(color: Colors.grey[600]),
              ),
            ),
            TextButton(
              onPressed: () async {
                if (_newGroup != null && _newGroup != "") {
                  context.podcastState
                      .addGroup(PodcastGroup.create(name: _newGroup!));
                  Navigator.of(context).pop();
                }
              },
              child:
                  Text(s.confirm, style: TextStyle(color: context.accentColor)),
            )
          ],
          title: SizedBox(width: context.width - 160, child: Text(s.newGroup)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              TextField(
                decoration: InputDecoration(
                  contentPadding: EdgeInsets.symmetric(horizontal: 10),
                  hintText: s.newGroup,
                  hintStyle: TextStyle(fontSize: 18),
                  filled: true,
                  focusedBorder: UnderlineInputBorder(
                    borderSide:
                        BorderSide(color: context.accentColor, width: 2.0),
                  ),
                  enabledBorder: UnderlineInputBorder(
                    borderSide:
                        BorderSide(color: context.accentColor, width: 2.0),
                  ),
                ),
                cursorRadius: Radius.circular(2),
                autofocus: true,
                maxLines: 1,
                controller: _controller,
                onChanged: (value) {
                  _newGroup = value;
                },
              ),
              Container(
                alignment: Alignment.centerLeft,
                child: (_error == 1)
                    ? Text(
                        s.groupExisted,
                        style: TextStyle(color: Colors.red[400]),
                      )
                    : Center(),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
