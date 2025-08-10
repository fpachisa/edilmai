import 'package:flutter/material.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: const [
          Icon(Icons.person_rounded, size: 48),
          SizedBox(height: 12),
          Text('Profile coming soon…'),
        ],
      ),
    );
  }
}

