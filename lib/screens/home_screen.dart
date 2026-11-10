import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import '../models/resume_result.dart';
import '../services/api_service.dart';
import '../widgets/job_card.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final ApiService _api = ApiService();
  ResumeResult? _result;
  bool _loading = false;
  String? _error;
  String? _selectedFile;

  Future<void> _pickAndAnalyze() async {
    setState(() {
      _error = null;
    });

    final picked = await FilePicker.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf'],
      // withData: false,
    );
    if (picked.isEmpty) return;

    final file = picked.single;
    if (file.path == null) {
      setState(() => _error = 'Could not access the selected file.');
      return;
    }
    if (await File(file.path!).length() > 5 * 1024 * 1024) {
      setState(() => _error = 'Please select a PDF smaller than 5 MB.');
      return;
    }

    setState(() {
      _loading = true;
      _selectedFile = file.name;
      _result = null;
    });

    try {
      final result = await _api.analyzeResume(
        filePath: file.path!,
        fileName: file.name,
      );
      if (!mounted) return;
      setState(() => _result = result);
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = e.toString().replaceFirst('Exception: ', ''));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('CareerAI',
            style: TextStyle(fontWeight: FontWeight.bold)),
        actions: [
          IconButton(
            tooltip: 'About',
            onPressed: () => showAboutDialog(
              context: context,
              applicationName: 'CareerAI',
              applicationVersion: '1.0.0',
              children: const [
                Text(
                    'Upload a PDF resume to extract skills and discover matching sample jobs.')
              ],
            ),
            icon: const Icon(Icons.info_outline),
          ),
        ],
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(18),
          children: [
            const Text(
              'Your next career move starts here.',
              style: TextStyle(fontSize: 25, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              'Analyze your resume, discover your strengths and find jobs that match your skills.',
              style: TextStyle(color: Colors.grey.shade700, height: 1.4),
            ),
            const SizedBox(height: 22),
            _UploadPanel(
              loading: _loading,
              selectedFile: _selectedFile,
              onTap: _pickAndAnalyze,
            ),
            if (_error != null) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.red.shade50,
                  borderRadius: BorderRadius.circular(12),
                ),
                child:
                    Text(_error!, style: TextStyle(color: Colors.red.shade800)),
              ),
            ],
            if (_result != null) ...[
              const SizedBox(height: 24),
              _AnalysisSection(result: _result!),
            ],
            const SizedBox(height: 30),
            Text(
              'How it works',
              style: Theme.of(context)
                  .textTheme
                  .titleLarge
                  ?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            const _StepTile(
                number: '1',
                title: 'Upload your PDF',
                subtitle: 'Choose your latest resume.'),
            const _StepTile(
                number: '2',
                title: 'Extract your profile',
                subtitle: 'CareerAI identifies skills and experience.'),
            const _StepTile(
                number: '3',
                title: 'Explore matching jobs',
                subtitle: 'See matched and missing skills for each role.'),
            const SizedBox(height: 20),
            Text(
              'MVP note: job listings are sample data, not live vacancies.',
              style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }
}

class _UploadPanel extends StatelessWidget {
  final bool loading;
  final String? selectedFile;
  final VoidCallback onTap;

  const _UploadPanel({
    required this.loading,
    required this.selectedFile,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFDDE2F5)),
      ),
      child: Column(
        children: [
          Container(
            height: 58,
            width: 58,
            decoration: BoxDecoration(
              color: const Color(0xFFECEEFF),
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Icon(Icons.picture_as_pdf_outlined,
                color: Color(0xFF4457D9), size: 30),
          ),
          const SizedBox(height: 14),
          const Text('Upload your resume',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 6),
          Text(
            selectedFile ?? 'PDF format · Maximum file size 5 MB',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.grey.shade600),
          ),
          const SizedBox(height: 18),
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: loading ? null : onTap,
              icon: loading
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: Colors.white),
                    )
                  : const Icon(Icons.upload_file),
              label: Text(
                  loading ? 'Analyzing resume...' : 'Choose PDF & Analyze'),
            ),
          ),
        ],
      ),
    );
  }
}

class _AnalysisSection extends StatelessWidget {
  final ResumeResult result;
  const _AnalysisSection({required this.result});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Resume analysis',
            style: Theme.of(context)
                .textTheme
                .titleLarge
                ?.copyWith(fontWeight: FontWeight.bold)),
        const SizedBox(height: 12),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(result.filename,
                    style: const TextStyle(fontWeight: FontWeight.w600)),
                const SizedBox(height: 8),
                Text(result.summary),
                const SizedBox(height: 14),
                Row(
                  children: [
                    _Metric(value: '${result.skills.length}', label: 'Skills'),
                    _Metric(
                        value: result.experienceYears == null
                            ? 'N/A'
                            : '${result.experienceYears} yrs',
                        label: 'Experience'),
                    _Metric(value: '${result.wordCount}', label: 'Words'),
                  ],
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        Text('Detected skills',
            style: Theme.of(context)
                .textTheme
                .titleMedium
                ?.copyWith(fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        if (result.skills.isEmpty)
          const Text(
              'No known skills found. Add a clear Skills section to your resume.')
        else
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children:
                result.skills.map((skill) => Chip(label: Text(skill))).toList(),
          ),
        const SizedBox(height: 18),
        Text('Resume improvement tips',
            style: Theme.of(context)
                .textTheme
                .titleMedium
                ?.copyWith(fontWeight: FontWeight.bold)),
        ...result.suggestions.map((tip) => ListTile(
              contentPadding: EdgeInsets.zero,
              leading:
                  const Icon(Icons.lightbulb_outline, color: Color(0xFFB7791F)),
              title: Text(tip, style: const TextStyle(fontSize: 14)),
            )),
        const SizedBox(height: 12),
        Text('Recommended jobs',
            style: Theme.of(context)
                .textTheme
                .titleLarge
                ?.copyWith(fontWeight: FontWeight.bold)),
        const SizedBox(height: 10),
        ...result.jobs.map((job) => JobCard(job: job)),
      ],
    );
  }
}

class _Metric extends StatelessWidget {
  final String value;
  final String label;
  const _Metric({required this.value, required this.label});

  @override
  Widget build(BuildContext context) => Expanded(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(value,
                style:
                    const TextStyle(fontSize: 19, fontWeight: FontWeight.bold)),
            Text(label,
                style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
          ],
        ),
      );
}

class _StepTile extends StatelessWidget {
  final String number;
  final String title;
  final String subtitle;
  const _StepTile(
      {required this.number, required this.title, required this.subtitle});

  @override
  Widget build(BuildContext context) => ListTile(
        contentPadding: EdgeInsets.zero,
        leading: CircleAvatar(
          backgroundColor: const Color(0xFFECEEFF),
          foregroundColor: const Color(0xFF4457D9),
          child:
              Text(number, style: const TextStyle(fontWeight: FontWeight.bold)),
        ),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
        subtitle: Text(subtitle),
      );
}
