import 'package:flutter/material.dart';

const Color _editorAccent = Color(0xFFC7A27C);
const Color _editorForeground = Colors.black;

class ApprovedBadge extends StatelessWidget {
  const ApprovedBadge({super.key, this.label = 'ONAYLI'});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: _editorAccent,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.verified,
            size: 14,
            color: _editorForeground,
          ),
          const SizedBox(width: 4),
          Text(
            label,
            style: const TextStyle(
              color: _editorForeground,
              fontSize: 11,
              fontWeight: FontWeight.bold,
              height: 1,
            ),
          ),
        ],
      ),
    );
  }
}

class MarketActionButton extends StatelessWidget {
  const MarketActionButton({
    super.key,
    this.label = 'Trendyol Market',
    this.onTap,
    this.padding = const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
  });

  final String label;
  final VoidCallback? onTap;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(6),
        child: Ink(
          padding: padding,
          decoration: BoxDecoration(
            color: _editorAccent,
            borderRadius: BorderRadius.circular(6),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Flexible(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: _editorForeground,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              const SizedBox(width: 6),
              const Icon(
                Icons.open_in_new,
                size: 15,
                color: _editorForeground,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
