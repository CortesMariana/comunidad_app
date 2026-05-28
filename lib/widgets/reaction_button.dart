import 'package:flutter/material.dart';

class ReactionButton extends StatelessWidget {
  final IconData icon;
  final int count;
  final bool isLiked;
  final VoidCallback onTap;
  final Color color;

  const ReactionButton({
    super.key,
    required this.icon,
    required this.count,
    this.isLiked = false,
    required this.onTap,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.3),
              shape: BoxShape.circle,
            ),
            child: Icon(
              icon,
              color: isLiked ? color : Colors.white,
              size: 28,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            _formatCount(count),
            style: const TextStyle(color: Colors.white, fontSize: 12),
          ),
        ],
      ),
    );
  }

  String _formatCount(int count) {
    if (count >= 1000) {
      return '${(count / 1000).toStringAsFixed(1)}K';
    }
    return count.toString();
  }
}