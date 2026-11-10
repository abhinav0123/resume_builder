import 'package:dio/dio.dart';
import '../models/resume_result.dart';

class ApiService {
  static const String baseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'https://careerai-api.onrender.com',
  );

  final Dio _dio = Dio(
    BaseOptions(
      baseUrl: baseUrl,
      connectTimeout: const Duration(seconds: 20),
      receiveTimeout: const Duration(seconds: 60),
      sendTimeout: const Duration(seconds: 60),
      headers: {'Accept': 'application/json'},
    ),
  );

  Future<ResumeResult> analyzeResume({
    required String filePath,
    required String fileName,
  }) async {
    final formData = FormData.fromMap({
      'file': await MultipartFile.fromFile(filePath, filename: fileName),
    });

    try {
      final response = await _dio.post(
        '/api/v1/resumes/analyze',
        data: formData,
        options: Options(contentType: 'multipart/form-data'),
      );
      print('Response: Statuscode: ${response.statusCode}');
      return ResumeResult.fromJson(
        Map<String, dynamic>.from(response.data),
      );
    } on DioException catch (error) {
      print('StatusCode: ${error.response?.statusCode}');

      final detail = error.response?.data is Map
          ? error.response?.data['detail']?.toString()
          : null;
      throw Exception(detail ?? error.message ?? 'Unable to analyze resume');
    }
  }
}
