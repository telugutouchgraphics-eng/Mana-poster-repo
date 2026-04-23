import 'package:flutter/material.dart';

import 'package:mana_poster/features/admin/models/admin_dashboard_models.dart';

class AdminQuickActionTile extends StatelessWidget {
  const AdminQuickActionTile({super.key, required this.action});

  final AdminQuickAction action;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: () {},
        child: Ink(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            color: const Color(0xFFF8F7FF),
            border: Border.all(color: const Color(0xFFEAE5FF)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Icon(action.icon, size: 18, color: const Color(0xFF5A32E0)),
              const SizedBox(width: 8),
              Text(
                action.label,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF30245E),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
