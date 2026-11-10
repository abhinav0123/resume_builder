import 'package:flutter/material.dart';
import '../models/resume_result.dart';

class JobCard extends StatelessWidget {
  final JobMatch job;
  const JobCard({super.key, required this.job});

  @override
  Widget build(BuildContext context) {
    final scoreColor = job.matchScore >= 75
        ? Colors.green
        : job.matchScore >= 50
            ? Colors.orange
            : Colors.red;
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(job.title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 4),
                      Text('${job.company} · ${job.location}', style: TextStyle(color: Colors.grey.shade600, fontSize: 12)),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
                  decoration: BoxDecoration(
                    color: scoreColor.withValues(alpha: 0.10),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    '${job.matchScore}% match',
                    style: TextStyle(color: scoreColor, fontWeight: FontWeight.bold, fontSize: 12),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(job.description, style: const TextStyle(fontSize: 13)),
            const SizedBox(height: 12),
            if (job.matchedSkills.isNotEmpty) ...[
              const Text('Matched skills', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 12)),
              const SizedBox(height: 6),
              Wrap(
                spacing: 6,
                children: job.matchedSkills.map((s) => Chip(
                  label: Text(s, style: const TextStyle(fontSize: 11)),
                  visualDensity: VisualDensity.compact,
                  backgroundColor: Colors.green.shade50,
                  side: BorderSide.none,
                )).toList(),
              ),
            ],
            if (job.missingSkills.isNotEmpty) ...[
              const SizedBox(height: 6),
              const Text('Skills to improve', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 12)),
              const SizedBox(height: 6),
              Wrap(
                spacing: 6,
                children: job.missingSkills.map((s) => Chip(
                  label: Text(s, style: const TextStyle(fontSize: 11)),
                  visualDensity: VisualDensity.compact,
                  backgroundColor: Colors.orange.shade50,
                  side: BorderSide.none,
                )).toList(),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
