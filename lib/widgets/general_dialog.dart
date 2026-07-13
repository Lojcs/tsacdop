import 'package:flutter/material.dart';

import '../util/extension_helper.dart';

Future generalDialog(
  BuildContext context, {
  Widget? title,
  Widget? content,
  List<Widget>? actions,
}) async => await showGeneralDialog(
  context: context,
  barrierDismissible: true,
  barrierLabel: MaterialLocalizations.of(context).modalBarrierDismissLabel,
  barrierColor: Colors.black54,
  transitionDuration: const Duration(milliseconds: 200),
  pageBuilder: (context, animaiton, secondaryAnimation) => AlertDialog(
    backgroundColor: context.surface,
    elevation: 2,
    shape: RoundedRectangleBorder(
      borderRadius: context.radiusMedium,
      side: context.trueBlack ? BorderSide(color: context.primaryColor) : .none,
    ),
    titlePadding: EdgeInsets.only(top: 20, bottom: 8, left: 20, right: 20),
    title: SizedBox(width: context.width - 120, child: title),
    content: content,
    contentPadding: EdgeInsets.only(bottom: 20, left: 20, right: 20),
    actions: actions,
  ),
);

Future showGeneralSheet(
  BuildContext context, {
  Widget? child,
  String? title,
  Color? color,
}) async => await showModalBottomSheet(
  useRootNavigator: true,
  isScrollControlled: true,
  shape: RoundedRectangleBorder(
    borderRadius: BorderRadius.only(
      topLeft: context.radiusMedium.topLeft,
      topRight: context.radiusMedium.topRight,
    ),
  ),
  elevation: 2,
  // backgroundColor: color?.toWeakBackround(context) ?? context.surface,
  context: context,
  builder: (context) {
    final statusHeight = MediaQuery.of(context).padding.top;
    return SafeArea(
      child: Container(
        constraints: BoxConstraints(
          maxHeight: context.height - statusHeight - 80,
        ),
        child: Stack(
          alignment: Alignment.topCenter,
          children: [
            if (context.trueBlack)
              Container(
                height: 32,
                decoration: BoxDecoration(
                  borderRadius: context.radiusMedium,
                  color: color ?? context.primaryColor,
                ),
              ),
            if (context.trueBlack)
              Container(
                height: 32,
                margin: EdgeInsets.only(top: 1.0),
                decoration: BoxDecoration(
                  borderRadius: context.radiusMedium,
                  color: color?.toWeakBackround(context) ?? context.surface,
                ),
              ),
            Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  height: 4,
                  width: 25,
                  margin: EdgeInsets.only(top: 10.0, bottom: 2.0),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(2.0),
                    color: context.colorScheme.onSurface,
                  ),
                ),
                Padding(
                  padding: EdgeInsets.only(
                    left: 50,
                    right: 50,
                    top: 6.0,
                    bottom: 10,
                  ),
                  child: Text(
                    title!,
                    style: context.textTheme.titleSmall,
                    textAlign: TextAlign.center,
                    maxLines: 1,
                    overflow: TextOverflow.clip,
                  ),
                ),
                Divider(height: 1),
                Flexible(child: SingleChildScrollView(child: child)),
                SizedBox(height: 30),
              ],
            ),
          ],
        ),
      ),
    );
  },
);
