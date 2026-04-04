import 'package:flutter/material.dart';

import '../models/points_models.dart';

class DailyTaskTile extends StatelessWidget {
  const DailyTaskTile({super.key, required this.task});

  final DailyTask task;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0x0F000000)),
        boxShadow: const [BoxShadow(color: Color(0x12000000), blurRadius: 10, offset: Offset(0, 4))],
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(color: task.iconBackground, shape: BoxShape.circle),
                child: Icon(task.icon, color: const Color(0xFF3D4956), size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(task.title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Color(0xFF1A1F26))),
                    const SizedBox(height: 2),
                    Text(task.description, style: const TextStyle(fontSize: 12, color: Color(0xFF7D8792))),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFF2E2),
                  borderRadius: BorderRadius.circular(999),
                  border: Border.all(color: const Color(0xFFFFDFBE)),
                ),
                child: Text('+${task.reward}', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Color(0xFFE7872E))),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(999),
                  child: LinearProgressIndicator(
                    value: task.progress,
                    minHeight: 6,
                    backgroundColor: const Color(0xFFE9EDF1),
                    valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF8EC7FF)),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Text('${task.current}/${task.target}', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Color(0xFF66707B))),
            ],
          ),
        ],
      ),
    );
  }
}
