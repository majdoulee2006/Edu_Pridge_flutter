import 'package:flutter/material.dart';

class ContactTileWidget extends StatelessWidget {
  final String title;
  final String? subtitle;
  final String? avatarUrl;
  final int unreadCount;
  final VoidCallback onTap;

  const ContactTileWidget({
    Key? key,
    required this.title,
    this.subtitle,
    this.avatarUrl,
    this.unreadCount = 0,
    required this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ListTile(
      onTap: onTap,
      leading: CircleAvatar(
        backgroundImage: avatarUrl != null ? NetworkImage(avatarUrl!) : null,
        child: avatarUrl == null ? Text(title[0].toUpperCase()) : null,
      ),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
      subtitle: subtitle != null
          ? Text(
              subtitle!,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            )
          : null,
      trailing: unreadCount > 0
          ? Container(
              padding: const EdgeInsets.all(6),
              decoration: const BoxDecoration(
                color: Colors.red,
                shape: BoxShape.circle,
              ),
              child: Text(
                unreadCount.toString(),
                style: const TextStyle(color: Colors.white, fontSize: 12),
              ),
            )
          : null,
    );
  }
}
