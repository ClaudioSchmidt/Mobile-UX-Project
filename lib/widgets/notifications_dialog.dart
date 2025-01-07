import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../theme.dart';

class NotificationsDialog extends StatelessWidget {
  final List<Map<String, dynamic>> notifications;
  final Function() onMarkAllRead;

  const NotificationsDialog({
    super.key,
    required this.notifications,
    required this.onMarkAllRead,
  });

  Widget _getNotificationIcon(String type) {
    switch (type) {
      case 'chat_request':
        return const Icon(Icons.person_add, color: Colors.blue);
      case 'like':
        return const Icon(Icons.favorite, color: Colors.red);
      case 'system':
        return const Icon(Icons.system_update, color: Colors.orange);
      case 'message':
        return const Icon(Icons.message, color: Colors.green);
      default:
        return const Icon(Icons.notifications);
    }
  }

  String _formatNotificationTime(DateTime time) {
    final now = DateTime.now();
    final difference = now.difference(time);

    if (difference.inMinutes < 60) {
      return '${difference.inMinutes} minutes ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours} hours ago';
    } else {
      return DateFormat('dd.MM.yy HH:mm').format(time);
    }
  }

  @override
  Widget build(BuildContext context) {
    final customColors = Theme.of(context).extension<CustomColors>()!;
    
    return Dialog(
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.8,
          maxWidth: MediaQuery.of(context).size.width * 0.9,
        ),
        child: SizedBox(
          width: 400,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Notifications',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Row(
                      children: [
                        TextButton(
                          onPressed: () {
                            onMarkAllRead();
                            Navigator.pop(context);
                          },
                          child: const Text('Read all'),
                        ),
                        IconButton(
                          icon: const Icon(Icons.close),
                          onPressed: () => Navigator.pop(context),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const Divider(height: 1),
              Expanded(
                child: ListView.builder(
                  itemCount: notifications.length,
                  itemBuilder: (context, index) {
                    final notification = notifications[index];
                    return ListTile(
                      leading: _getNotificationIcon(notification['type']),
                      title: Text(
                        notification['title'],
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(notification['message']),
                          Text(
                            _formatNotificationTime(notification['time']),
                            style: const TextStyle(fontSize: 12, color: Colors.grey),
                          ),
                          if (notification['actions'] != null)
                            Row(
                              children: [
                                TextButton(
                                  onPressed: () => Navigator.pop(context),
                                  child: Text('Accept', 
                                    style: TextStyle(color: customColors.success)),
                                ),
                                TextButton(
                                  onPressed: () => Navigator.pop(context),
                                  child: const Text('Reject', 
                                    style: TextStyle(color: Colors.red)),
                                ),
                              ],
                            ),
                        ],
                      ),
                      onTap: () => Navigator.pop(context),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
