class ResumeResult {
  final String resumeId;
  final String filename;
  final List<String> skills;
  final double? experienceYears;
  final int wordCount;
  final String summary;
  final List<String> suggestions;
  final List<JobMatch> jobs;

  ResumeResult({
    required this.resumeId,
    required this.filename,
    required this.skills,
    required this.experienceYears,
    required this.wordCount,
    required this.summary,
    required this.suggestions,
    required this.jobs,
  });

  factory ResumeResult.fromJson(Map<String, dynamic> json) {
    final analysis = Map<String, dynamic>.from(json['analysis'] ?? {});
    return ResumeResult(
      resumeId: json['resume_id'] ?? '',
      filename: json['filename'] ?? '',
      skills: List<String>.from(analysis['skills'] ?? []),
      experienceYears: (analysis['experience_years'] as num?)?.toDouble(),
      wordCount: analysis['word_count'] ?? 0,
      summary: analysis['summary'] ?? '',
      suggestions: List<String>.from(analysis['suggestions'] ?? []),
      jobs: (json['recommended_jobs'] as List? ?? [])
          .map((item) => JobMatch.fromJson(Map<String, dynamic>.from(item)))
          .toList(),
    );
  }
}

class JobMatch {
  final String id;
  final String title;
  final String company;
  final String location;
  final int matchScore;
  final List<String> matchedSkills;
  final List<String> missingSkills;
  final List<String> requiredSkills;
  final String description;

  JobMatch({
    required this.id,
    required this.title,
    required this.company,
    required this.location,
    required this.matchScore,
    required this.matchedSkills,
    required this.missingSkills,
    required this.requiredSkills,
    required this.description,
  });

  factory JobMatch.fromJson(Map<String, dynamic> json) => JobMatch(
        id: json['id'] ?? '',
        title: json['title'] ?? '',
        company: json['company'] ?? '',
        location: json['location'] ?? '',
        matchScore: json['match_score'] ?? 0,
        matchedSkills: List<String>.from(json['matched_skills'] ?? []),
        missingSkills: List<String>.from(json['missing_skills'] ?? []),
        requiredSkills: List<String>.from(json['skills'] ?? []),
        description: json['description'] ?? '',
      );
}
