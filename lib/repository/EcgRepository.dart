import 'package:flutter/services.dart' show rootBundle;

class HeartRateRepository {
  List<double> ecg = [];
  Future<List<double>> readHeartRateFile(String path) async {
    print("reading ecg from file ...");
    List<double> heartrates = [];
    try {
      final content = await rootBundle.loadString(path);
      final nums = content.split("\n").toList();
      for (var value in nums) {
        try {
          heartrates.add(double.parse(value));
        } catch (e) {
          heartrates.add(0.0);
        }
      }
      print("data length ${heartrates.length}");
      this.ecg = heartrates;
      return heartrates;
    } catch (e) {
      print(e);
      return heartrates;
    }
  }
}
