import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:provider/provider.dart';

import '../state/podcast_group.dart';
import '../state/podcast_state.dart';
import '../util/extension_helper.dart';
import '../widgets/general_dialog.dart';
import 'podcast_settings.dart';

class PodcastGroupList extends StatefulWidget {
  final PodcastGroup? group;
  const PodcastGroupList({this.group, super.key});
  @override
  _PodcastGroupListState createState() => _PodcastGroupListState();
}

class _PodcastGroupListState extends State<PodcastGroupList> {
  PodcastGroup? _group;
  @override
  void initState() {
    super.initState();
    _group = widget.group;
  }

  @override
  void didUpdateWidget(PodcastGroupList oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.group != widget.group) setState(() => _group = widget.group);
  }

  @override
  Widget build(BuildContext context) {
    return _group!.podcastList.isEmpty
        ? Container(
            color: context.primaryColor,
          )
        : Container(
            color: context.accentBackgroundWeak,
            child: ReorderableListView(
              onReorder: (oldIndex, newIndex) {
                setState(() {
                  _group!.reorderGroup(oldIndex, newIndex);
                });
                context.read<GroupList>().addToOrderChanged(_group);
              },
              children: _group!.podcasts.map<Widget>(
                (podcastLocal) {
                  return Container(
                    margin: EdgeInsets.only(top: 0.5, bottom: 0.5),
                    decoration: BoxDecoration(color: context.surface),
                    key: ObjectKey(podcastLocal.title),
                    child: _PodcastCard(
                      podcastId: podcastLocal.id,
                      group: _group,
                    ),
                  );
                },
              ).toList(),
            ),
          );
  }
}

class _PodcastCard extends StatefulWidget {
  final String podcastId;
  final PodcastGroup? group;
  const _PodcastCard({required this.podcastId, this.group});
  @override
  State<_PodcastCard> createState() => __PodcastCardState();
}

class __PodcastCardState extends State<_PodcastCard>
    with SingleTickerProviderStateMixin {
  late bool _addGroup;
  late List<PodcastGroup?> _selectedGroups;
  late List<PodcastGroup?> _belongGroups;
  late AnimationController _controller;
  late Animation _animation;
  double? _value;
  final int _seconds = 0;
  int? _skipSeconds;

  late final PodcastState pState = context.podcastState;
  @override
  void initState() {
    super.initState();
    _addGroup = false;
    _selectedGroups = [widget.group];
    _value = 0;
    _controller =
        AnimationController(vsync: this, duration: Duration(milliseconds: 300));
    _animation = Tween<double>(begin: 0.0, end: 1.0).animate(_controller)
      ..addListener(
        () {
          setState(() {
            _value = _animation.value;
          });
        },
      );
  }

  @override
  Widget build(BuildContext context) {
    final s = context.s;
    final groupList = context.watch<GroupList>();
    _belongGroups = groupList.getPodcastGroup(widget.podcastId);
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
                        Row(
                          children: _belongGroups.map((group) {
                            return Container(
                                padding: EdgeInsets.only(right: 5.0),
                                child: Text(group!.name));
                          }).toList(),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                      icon: Icon(Icons.add),
                      splashRadius: 20,
                      tooltip: s.menu,
                      onPressed: () => setState(() => _addGroup = !_addGroup)),
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
        !_addGroup
            ? Center()
            : Container(
                decoration: BoxDecoration(
                  color: context.surface,
                ),
                // border: Border(
                //     bottom: BorderSide(
                //         color: Theme.of(context).primaryColorDark),
                //     top: BorderSide(
                //         color: Theme.of(context).primaryColorDark))),
                height: 50,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.start,
                  children: <Widget>[
                    Expanded(
                      child: SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                            children: groupList.groups.map<Widget>((group) {
                          return Container(
                            padding: EdgeInsets.only(left: 5.0),
                            child: FilterChip(
                              backgroundColor: context.accentBackground,
                              selectedColor: context.accentColor,
                              key: ValueKey<String>(group!.id),
                              label: Text(group.name),
                              selected: _selectedGroups.contains(group),
                              onSelected: (value) {
                                setState(() {
                                  if (!value) {
                                    _selectedGroups.remove(group);
                                  } else {
                                    _selectedGroups.add(group);
                                  }
                                });
                              },
                            ),
                          );
                        }).toList()),
                      ),
                    ),
                    Material(
                      color: Colors.transparent,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: <Widget>[
                          IconButton(
                            icon: Icon(Icons.clear),
                            splashRadius: 20,
                            onPressed: () => setState(() {
                              _addGroup = false;
                            }),
                          ),
                          IconButton(
                            icon: Icon(Icons.done),
                            splashRadius: 20,
                            onPressed: () async {
                              if (_selectedGroups.isNotEmpty) {
                                setState(() {
                                  _addGroup = false;
                                });
                                await groupList.changeGroup(
                                  pState[widget.podcastId],
                                  _selectedGroups,
                                );
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
                            },
                          ),
                        ],
                      ),
                    )
                  ],
                )),
      ],
    );
  }
}

class RenameGroup extends StatefulWidget {
  final PodcastGroup? group;
  const RenameGroup({this.group, super.key});
  @override
  State<RenameGroup> createState() => _RenameGroupState();
}

class _RenameGroupState extends State<RenameGroup> {
  TextEditingController? _controller;
  String? _newName;
  int? _error;

  @override
  void initState() {
    super.initState();
    _error = 0;
    _controller = TextEditingController(text: widget.group!.name);
  }

  @override
  void dispose() {
    _controller!.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    var groupList = Provider.of<GroupList>(context, listen: false);
    List list = groupList.groups.map((e) => e!.name).toList();
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
                if (list.contains(_newName)) {
                  setState(() => _error = 1);
                } else {
                  final newGroup = PodcastGroup(_newName!,
                      color: widget.group!.color,
                      id: widget.group!.id,
                      podcastList: widget.group!.podcastList);
                  groupList.updateGroup(newGroup);
                  Navigator.of(context).pop();
                }
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
    );
  }
}
