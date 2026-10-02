import 'dart:convert';

import 'package:flutter/material.dart';
import '../../theme.dart';

class InitialsAvatar extends StatelessWidget {
  const InitialsAvatar(this.initials,
      {super.key, this.radius = 22, this.color});
  final String initials;
  final double radius;
  final Color? color;
  @override
  Widget build(BuildContext context) => CircleAvatar(
      radius: radius,
      backgroundColor: (color ?? brandBlue).withOpacity(.12),
      child: Text(initials,
          style: TextStyle(
              color: color ?? brandBlue,
              fontWeight: FontWeight.w800,
              fontSize: radius * .55)));
}

class UserAvatar extends StatelessWidget {
  const UserAvatar({
    super.key,
    required this.name,
    this.avatarBase64 = '',
    this.radius = 22,
  });

  final String name;
  final String avatarBase64;
  final double radius;

  @override
  Widget build(BuildContext context) {
    MemoryImage? image;
    if (avatarBase64.isNotEmpty) {
      try {
        image = MemoryImage(base64Decode(avatarBase64));
      } on FormatException {
        image = null;
      }
    }
    return CircleAvatar(
      radius: radius,
      backgroundColor: brandBlue.withOpacity(.12),
      backgroundImage: image,
      child: image == null
          ? Text(
              name.characters.take(2).toString().toUpperCase(),
              style: TextStyle(
                color: brandBlue,
                fontWeight: FontWeight.w800,
                fontSize: radius * .55,
              ),
            )
          : null,
    );
  }
}

class SectionTitle extends StatelessWidget {
  const SectionTitle(this.title, {super.key, this.leading, this.action});
  final String title;
  final Widget? leading;
  final Widget? action;
  @override
  Widget build(BuildContext context) => Padding(
      padding: const EdgeInsets.fromLTRB(20, 18, 12, 10),
      child: Row(children: [
        if (leading != null) ...[
          leading!,
          const SizedBox(width: 8),
        ],
        Expanded(
            child: Text(title,
                style: TextStyle(
                    fontSize: 25,
                    fontWeight: FontWeight.w800,
                    color: Theme.of(context).colorScheme.onSurface))),
        if (action != null) action!
      ]));
}

class EmptyState extends StatelessWidget {
  const EmptyState(
      {super.key,
      required this.icon,
      required this.title,
      required this.subtitle});
  final IconData icon;
  final String title, subtitle;
  @override
  Widget build(BuildContext context) => Center(
      child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            CircleAvatar(
                radius: 34,
                backgroundColor: brandBlue.withOpacity(.1),
                child: Icon(icon, size: 32, color: brandBlue)),
            const SizedBox(height: 16),
            Text(title,
                style:
                    const TextStyle(fontSize: 19, fontWeight: FontWeight.w700)),
            const SizedBox(height: 6),
            Text(subtitle,
                textAlign: TextAlign.center,
                style: TextStyle(
                    color: Theme.of(context).colorScheme.onSurfaceVariant))
          ])));
}
