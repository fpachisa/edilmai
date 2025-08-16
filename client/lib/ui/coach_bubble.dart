import 'package:flutter/material.dart';
import 'app_theme.dart';

class CoachBubble extends StatelessWidget {
  final String message;
  final String? actionLabel;
  final VoidCallback? onAction;
  const CoachBubble({super.key, required this.message, this.actionLabel, this.onAction});

  @override
  Widget build(BuildContext context) {
    return Glass(
      radius: 20,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      child: Row(
        children: [
          const CircleAvatar(radius: 16, backgroundColor: Colors.transparent, child: Icon(Icons.support_agent_rounded, size: 20)),
          const SizedBox(width: 10),
          Expanded(child: Text(message, style: const TextStyle(color: Colors.white))),
          if (actionLabel != null && onAction != null) ...[
            const SizedBox(width: 8),
            TextButton(onPressed: onAction, child: Text(actionLabel!)),
          ],
        ],
      ),
    );
  }
}

