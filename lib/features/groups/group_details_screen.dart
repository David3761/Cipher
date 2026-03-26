import 'dart:ui';

import 'package:chat/core/database/app_database.dart';
import 'package:chat/core/theme/theme.dart';
import 'package:chat/features/groups/group_repository.dart';
import 'package:chat/features/key_management/key_controller.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

class GroupDetailsScreen extends ConsumerWidget {
  final Group group;

  const GroupDetailsScreen({super.key, required this.group});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final membersAsync = ref.watch(groupMembersStreamProvider(group.groupId));
    final myPubKey = ref.watch(
      keyControllerProvider.select((s) => s.publicKeyHex ?? ''),
    );
    final topPadding = MediaQuery.of(context).padding.top;

    final String displayName;
    final rawName = group.name;
    if (rawName != null && rawName.isNotEmpty) {
      displayName = rawName;
    } else {
      displayName = membersAsync.maybeWhen(
        data: (members) {
          final names = members
              .where((m) => m.publicKey != myPubKey)
              .map((m) => m.alias)
              .join(', ');
          return names.isNotEmpty ? names : 'Group';
        },
        orElse: () => 'Group',
      );
    }

    final String memberCountStr = membersAsync.maybeWhen(
      data: (members) => '${members.length} members',
      orElse: () => '',
    );

    return Scaffold(
      backgroundColor: AppColors.secondaryBackground,
      body: CustomScrollView(
        slivers: [
          SliverPersistentHeader(
            pinned: true,
            delegate: GroupHeaderDelegate(
              paddingTop: topPadding,
              displayName: displayName,
              memberCountStr: memberCountStr,
              onBack: () => Navigator.pop(context),
              backgroundColor: AppColors.secondaryBackground,
              scrolledColor: AppColors.secondaryBackground.withValues(
                alpha: 0.10,
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: membersAsync.when(
              loading: () => const Padding(
                padding: EdgeInsets.all(32.0),
                child: Center(child: CircularProgressIndicator()),
              ),
              error: (e, _) => Center(child: Text('Error: $e')),
              data: (members) {
                final isAdmin = members.any(
                  (m) => m.publicKey == myPubKey && m.isAdmin,
                );

                final minScrollHeight =
                    MediaQuery.of(context).size.height -
                    (kToolbarHeight + topPadding);

                return ConstrainedBox(
                  constraints: BoxConstraints(minHeight: minScrollHeight),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const SizedBox(height: 16),

                      Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 24.0,
                          vertical: 8.0,
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              '${members.length} member${members.length == 1 ? '' : 's'}',
                              style: Theme.of(context).textTheme.titleMedium
                                  ?.copyWith(fontWeight: FontWeight.bold),
                            ),
                            const Icon(Icons.search, color: AppColors.title),
                          ],
                        ),
                      ),

                      Container(
                        margin: const EdgeInsets.symmetric(horizontal: 16.0),
                        decoration: BoxDecoration(
                          color: Theme.of(context).cardColor,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Column(
                          children: [
                            if (isAdmin) ...[
                              ListTile(
                                leading: CircleAvatar(
                                  backgroundColor:
                                      AppColors.secondaryBackground,
                                  child: const Icon(
                                    Icons.add,
                                    color: AppColors.title,
                                  ),
                                ),
                                title: const Text('Add members'),
                                onTap: () {},
                              ),
                              const Divider(height: 1, indent: 64),
                              ListTile(
                                leading: CircleAvatar(
                                  backgroundColor:
                                      AppColors.secondaryBackground,
                                  child: const Icon(
                                    Icons.link,
                                    color: AppColors.title,
                                  ),
                                ),
                                title: const Text('Invite via link or QR code'),
                                onTap: () {},
                              ),
                              const Divider(height: 1, indent: 64),
                            ],

                            ...members.asMap().entries.map((entry) {
                              final index = entry.key;
                              final member = entry.value;
                              final isMe = member.publicKey == myPubKey;
                              final colorIndex =
                                  member.alias.hashCode.abs() %
                                  AppColors.avatarColors.length;
                              final avatarColor =
                                  AppColors.avatarColors[colorIndex];

                              return Column(
                                children: [
                                  ListTile(
                                    leading: CircleAvatar(
                                      backgroundColor: avatarColor.withValues(
                                        alpha: 0.2,
                                      ),
                                      child: FaIcon(
                                        FontAwesomeIcons.solidUser,
                                        color:
                                            AppColors.avatarColors[colorIndex],
                                        size: 16,
                                      ),
                                    ),
                                    title: Text(isMe ? 'You' : member.alias),
                                    trailing: member.isAdmin
                                        ? const Text(
                                            'Admin',
                                            style: TextStyle(
                                              fontSize: 14,
                                              color: AppColors.grey,
                                            ),
                                          )
                                        : null,
                                  ),
                                  if (index < members.length - 1)
                                    const Divider(height: 1, indent: 64),
                                ],
                              );
                            }),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),

                      Container(
                        margin: const EdgeInsets.symmetric(horizontal: 16.0),
                        decoration: BoxDecoration(
                          color: Theme.of(context).cardColor,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: ListTile(
                          title: const Text(
                            'Exit group',
                            style: TextStyle(color: Colors.red, fontSize: 16),
                          ),
                          onTap: () {
                            // TODO: Implement exit
                          },
                        ),
                      ),

                      const Padding(
                        padding: EdgeInsets.symmetric(
                          horizontal: 24.0,
                          vertical: 16.0,
                        ),
                        child: Text(
                          'Created by you.\nCreated 11 Apr 2020.',
                          style: TextStyle(color: AppColors.grey, fontSize: 13),
                        ),
                      ),
                      const SizedBox(height: 32),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class GroupHeaderDelegate extends SliverPersistentHeaderDelegate {
  final double paddingTop;
  final String displayName;
  final String memberCountStr;
  final VoidCallback onBack;
  final Color backgroundColor;
  final Color scrolledColor;

  GroupHeaderDelegate({
    required this.paddingTop,
    required this.displayName,
    required this.memberCountStr,
    required this.onBack,
    required this.backgroundColor,
    required this.scrolledColor,
  });

  @override
  double get minExtent => kToolbarHeight + paddingTop;

  @override
  double get maxExtent => 260.0 + paddingTop;

  @override
  Widget build(
    BuildContext context,
    double shrinkOffset,
    bool overlapsContent,
  ) {
    final shrinkPercentage = (shrinkOffset / (maxExtent - minExtent)).clamp(
      0.0,
      1.0,
    );

    final expandedOpacity = (1 - shrinkPercentage * 3.0).clamp(0.0, 1.0);
    final collapsedOpacity = (shrinkPercentage * 4 - 1).clamp(0.0, 1.0);

    final currentBgColor = Color.lerp(
      backgroundColor,
      scrolledColor,
      shrinkPercentage,
    );

    return ClipRRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 15.0, sigmaY: 15.0),
        child: Container(
          padding: EdgeInsets.only(top: paddingTop),
          decoration: BoxDecoration(
            color: currentBgColor,
            border: Border(
              bottom: BorderSide(
                color: AppColors.onSecondaryBackground.withValues(
                  alpha: 0.15 * shrinkPercentage,
                ),
                width: 0.5,
              ),
            ),
          ),
          child: Stack(
            fit: StackFit.expand,
            children: [
              Opacity(
                opacity: expandedOpacity,
                child: Align(
                  alignment: Alignment.center,
                  child: Padding(
                    padding: const EdgeInsets.only(top: 24.0),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        CircleAvatar(
                          radius: 50,
                          backgroundColor: AppColors.primaryBlue.withValues(
                            alpha: 0.2,
                          ),
                          child: const FaIcon(
                            FontAwesomeIcons.userGroup,
                            size: 34,
                            color: AppColors.primaryBlue,
                          ),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          displayName,
                          textAlign: TextAlign.center,
                          style: Theme.of(context).textTheme.headlineMedium
                              ?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: AppColors.title,
                              ),
                        ),
                        if (memberCountStr.isNotEmpty) ...[
                          const SizedBox(height: 4),
                          Text(
                            memberCountStr,
                            style: TextStyle(
                              color: Theme.of(
                                context,
                              ).colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ),

              Opacity(
                opacity: collapsedOpacity,
                child: Container(
                  height: kToolbarHeight,
                  alignment: Alignment.center,
                  padding: const EdgeInsets.symmetric(horizontal: 64),
                  child: Text(
                    displayName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),

              Positioned(
                top: 4,
                left: 4,
                child: IconButton(
                  icon: const FaIcon(
                    FontAwesomeIcons.angleLeft,
                    color: AppColors.title,
                    size: 24,
                  ),
                  onPressed: onBack,
                ),
              ),

              Positioned(
                top: 4,
                right: 4,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: const FaIcon(
                        FontAwesomeIcons.qrcode,
                        color: AppColors.title,
                        size: 20,
                      ),
                      onPressed: () {},
                    ),
                    IconButton(
                      icon: const FaIcon(
                        FontAwesomeIcons.pen,
                        color: AppColors.title,
                        size: 18,
                      ),
                      onPressed: () {},
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  bool shouldRebuild(covariant GroupHeaderDelegate oldDelegate) {
    return displayName != oldDelegate.displayName ||
        memberCountStr != oldDelegate.memberCountStr ||
        paddingTop != oldDelegate.paddingTop ||
        backgroundColor != oldDelegate.backgroundColor ||
        scrolledColor != oldDelegate.scrolledColor;
  }
}
