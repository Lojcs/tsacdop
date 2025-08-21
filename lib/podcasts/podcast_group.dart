import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:provider/provider.dart';

import '../state/podcast_group.dart';
import '../state/podcast_state.dart';
import '../type/podcastgroup.dart';
import '../util/extension_helper.dart';
import '../widgets/general_dialog.dart';
import 'podcast_settings.dart';

class PodcastGroupList extends StatelessWidget {
  final String groupId;
  const PodcastGroupList({required this.groupId, super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: context.accentBackgroundWeak,
      child: Selector<PodcastState, List<String>>(
        selector: (_, pState) => pState.getGroupById(groupId).podcastIds,
        builder: (context, podcastIds, _) => ReorderableListView(
          onReorder: (oldIndex, newIndex) {
            if (newIndex > oldIndex) newIndex -= 1;
            context.podcastState
                .getGroupById(groupId)
                .reorderGroup(oldIndex, newIndex);
            Fluttertoast.showToast(
              msg: context.s.toastSettingSaved,
              gravity: ToastGravity.BOTTOM,
            );
          },
          children: podcastIds.map<Widget>(
            (podcastId) {
              return Container(
                margin: EdgeInsets.only(top: 0.5, bottom: 0.5),
                decoration: BoxDecoration(color: context.surface),
                key: ObjectKey(podcastId),
                child: _PodcastCard(
                  podcastId: podcastId,
                  groupId: groupId,
                ),
              );
            },
          ).toList(),
        ),
      ),
    );
  }
}

class _PodcastCard extends StatefulWidget {
  final String podcastId;
  final String? groupId;
  const _PodcastCard({required this.podcastId, this.groupId});
  @override
  State<_PodcastCard> createState() => __PodcastCardState();
}

class __PodcastCardState extends State<_PodcastCard>
    with SingleTickerProviderStateMixin {
  bool _addGroup = false;
  late final PodcastState pState = context.podcastState;
  @override
  Widget build(BuildContext context) {
    final s = context.s;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () => setState(() => _addGroup = !_addGroup),
            child: SizedBox(
              height: 100,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.start,
                crossAxisAlignment: CrossAxisAlignment.center,
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  Selector<PodcastState, Color>(
                    selector: (_, pState) =>
                        pState[widget.podcastId].primaryColor,
                    builder: (context, color, _) => Icon(
                      Icons.unfold_more,
                      color: color,
                    ),
                  ),
                  SizedBox(width: 5),
                  Selector<PodcastState, ImageProvider>(
                    selector: (_, pState) =>
                        pState[widget.podcastId].avatarImage,
                    builder: (context, avatarImage, _) => CircleAvatar(
                      radius: 25,
                      backgroundImage: avatarImage,
                    ),
                  ),
                  SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: <Widget>[
                        Selector<PodcastState, String>(
                          selector: (_, pState) =>
                              pState[widget.podcastId].title,
                          builder: (context, title, _) => Text(
                            title,
                            maxLines: 2,
                            overflow: TextOverflow.fade,
                            style: TextStyle(
                                fontWeight: FontWeight.bold, fontSize: 15),
                          ),
                        ),
                        Selector<PodcastState, List<String>>(
                          selector: (_, pState) =>
                              pState.findPodcastGroups(widget.podcastId),
                          builder: (context, groupIds, _) => Row(
                            children: groupIds.map((groupId) {
                              return Container(
                                padding: EdgeInsets.only(right: 5.0),
                                child: Selector<PodcastState, String>(
                                  selector: (_, pState) =>
                                      pState.getGroupById(groupId).name,
                                  builder: (context, name, _) => Text(name),
                                ),
                              );
                            }).toList(),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Icon(Icons.add),
                  IconButton(
                    icon: Icon(Icons.more_vert),
                    splashRadius: 20,
                    tooltip: s.menu,
                    onPressed: () => generalSheet(
                      context,
                      title: pState[widget.podcastId].title,
                      child: PodcastSetting(podcastId: widget.podcastId),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        AnimatedContainer(
          duration: Duration(milliseconds: 300),
          decoration: BoxDecoration(
            color: context.surface,
          ),
          // border: Border(
          //     bottom: BorderSide(
          //         color: Theme.of(context).primaryColorDark),
          //     top: BorderSide(
          //         color: Theme.of(context).primaryColorDark))),
          height: _addGroup ? 50 : 0,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.start,
            children: <Widget>[
              Expanded(
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Selector<PodcastState, List<String>>(
                    selector: (_, pState) => pState.groupIds,
                    builder: (context, groupIds, _) => Row(
                      children: groupIds.map<Widget>(
                        (groupId) {
                          return Container(
                            padding: EdgeInsets.only(left: 5.0),
                            child: Selector<PodcastState, bool>(
                              selector: (_, pState) => pState
                                  .getGroupById(groupId)
                                  .podcastIds
                                  .contains(widget.podcastId),
                              builder: (context, contains, _) => FilterChip(
                                backgroundColor: context.accentBackground,
                                selectedColor: context.accentColor,
                                key: ValueKey<String>(groupId),
                                label: Selector<PodcastState, String>(
                                  selector: (_, pState) =>
                                      pState.getGroupById(groupId).name,
                                  builder: (context, name, _) => Text(name),
                                ),
                                selected: contains,
                                onSelected: (value) {
                                  if (value) {
                                    pState.addPodcastToGroup(
                                        podcastId: widget.podcastId,
                                        groupId: groupId);
                                  } else {
                                    final groupIds = pState
                                        .findPodcastGroups(widget.podcastId);
                                    if (groupIds.length != 1) {
                                      pState.removePodcastFromGroup(
                                          podcastId: widget.podcastId,
                                          groupId: groupId);
                                      Fluttertoast.showToast(
                                        msg: s.toastSettingSaved,
                                        gravity: ToastGravity.BOTTOM,
                                      );
                                    } else {
                                      Fluttertoast.showToast(
                                        msg: s.toastOneGroup,
                                        gravity: ToastGravity.BOTTOM,
                                      );
                                    }
                                  }
                                },
                              ),
                            ),
                          );
                        },
                      ).toList(),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class RenameGroup extends StatefulWidget {
  final String groupId;
  const RenameGroup({required this.groupId, super.key});
  @override
  State<RenameGroup> createState() => _RenameGroupState();
}

class _RenameGroupState extends State<RenameGroup> {
  late final TextEditingController _controller = TextEditingController(
      text: context.podcastState.getGroupById(widget.groupId)!.name);
  String? _newName;

  @override
  void initState() {
    super.initState();
    _controller;
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
      child: AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: const BorderRadius.all(
            Radius.circular(20),
          ),
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
              if (_newName != null) {
                context.podcastState.modifyGroup(
                    widget.groupId, (group) => group.copyWith(name: _newName));

                Navigator.of(context).pop();
              }
            },
            child: Text(
              s.confirm,
              style: TextStyle(color: context.accentColor),
            ),
          )
        ],
        title: SizedBox(
          width: context.width - 160,
          child: Text(s.editGroupName),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            TextField(
              decoration: InputDecoration(
                contentPadding: EdgeInsets.symmetric(horizontal: 10),
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
                _newName = value;
              },
            ),
            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                s.groupExisted,
                style: TextStyle(color: Colors.red[400]),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
