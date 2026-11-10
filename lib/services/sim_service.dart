import 'package:career_ai/models/sim_model.dart';
import 'package:flutter/services.dart';

class SimService {
  static const MethodChannel _channel =
      MethodChannel('com.example.resume_improver/sim');

  Future<List<SimCard>> getSimCards() async {
    try {
      final List<dynamic> response = await _channel.invokeMethod('getSimCards');

      return response.map((sim) {
        return SimCard.fromMap(sim as Map);
      }).toList();
    } on PlatformException catch (e) {
      throw Exception(e.message ?? 'Unable to fetch SIM cards');
    } on MissingPluginException {
      throw Exception('SIM detection is not supported on this platform');
    }
  }
}
