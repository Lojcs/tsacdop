import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';

import '../../../../core/extension/extension_helper.dart';
import '../../../podcast/carousel/widget/podcast_carousel.dart';
import '../../../podcast/state/podcast_state.dart';
import '../../model/podcast_group.dart';

class GroupCard extends StatelessWidget {
  final String groupId;
  const GroupCard({super.key, required this.groupId});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: .all(8),
      padding: .only(top: 15),
      decoration: BoxDecoration(
        color: context.cardColorSchemeCard,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: context.trueBlack
              ? context.trueBlackBorderColor
              : Colors.transparent,
          width: 1.0,
        ),
        boxShadow: [
          BoxShadow(
            color: context.cardColorSchemeShadow,
            blurRadius: 5,
            spreadRadius: -3,
            offset: Offset.fromDirection(0, 0),
          ),
        ],
      ),
      child: Selector<PodcastState, PodcastGroup>(
        selector: (_, pState) => pState.getGroupById(groupId)!,
        builder: (context, group, _) => Column(
          children: [
            Text(group.name),
            DefaultTabController(
              length: group.podcastIds.isEmpty ? 3 : group.podcastIds.length,
              child: PodcastCarousel(groupId: groupId),
            ),
          ],
        ),
      ),
    );
  }
}
